param(
    [string]$OutJar = "$PSScriptRoot\..\.tools\sqlite-bundled-jvm-windows-arm64\sqlite-bundled-jvm-windows-arm64.jar",
    [string]$WorkDir = "$PSScriptRoot\..\.tools\sqlite-build",
    [string]$JdkHome = $env:JAVA_HOME,
    [string]$Msys2Root = $env:MSYS2_ROOT
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($JdkHome)) {
    throw "JAVA_HOME or -JdkHome is required."
}

$msys2Candidates = @($Msys2Root, "C:\msys64")
if (![string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) {
    $msys2Candidates += Join-Path $env:RUNNER_TEMP "setup-msys2\msys64"
}
$msys2Candidates = $msys2Candidates | Where-Object { ![string]::IsNullOrWhiteSpace($_) }

$clangBin = $msys2Candidates |
    ForEach-Object { Join-Path $_ "clangarm64\bin" } |
    Where-Object { (Test-Path (Join-Path $_ "clang.exe")) -and (Test-Path (Join-Path $_ "clang++.exe")) } |
    Select-Object -First 1

if ([string]::IsNullOrWhiteSpace($clangBin)) {
    throw "MSYS2 clangarm64 toolchain was not found. Checked: $($msys2Candidates -join ', ')"
}

$clang = Join-Path $clangBin "clang.exe"
$clangxx = Join-Path $clangBin "clang++.exe"

$sqliteVersion = "3.50.1"
$sqliteZipVersion = "3500100"
$sqliteZip = Join-Path $WorkDir "sqlite-amalgamation-$sqliteZipVersion.zip"
$sqliteDir = Join-Path $WorkDir "sqlite-amalgamation-$sqliteZipVersion"
$androidxArchive = Join-Path $WorkDir "androidx-sqlite-bundled.tar.gz"
$androidxDir = Join-Path $WorkDir "androidx-sqlite-bundled"
$androidxSqlite262Commit = "fe30df161d480829efb21f37ff67a9f8cac9c620"
$jarRoot = Join-Path $WorkDir "jarroot"

New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null

if (!(Test-Path $sqliteZip)) {
    Invoke-WebRequest `
        -Uri "https://www.sqlite.org/2025/sqlite-amalgamation-$sqliteZipVersion.zip" `
        -OutFile $sqliteZip
}
if (!(Test-Path (Join-Path $sqliteDir "sqlite3.c"))) {
    Expand-Archive -Path $sqliteZip -DestinationPath $WorkDir -Force
}

$sqliteHeader = Get-Content (Join-Path $sqliteDir "sqlite3.h") -Raw
if ($sqliteHeader -notmatch "#define\s+SQLITE_VERSION\s+`"$([regex]::Escape($sqliteVersion))`"") {
    throw "Downloaded SQLite amalgamation does not match $sqliteVersion."
}

if (!(Test-Path $androidxArchive)) {
    Invoke-WebRequest `
        -Uri "https://android.googlesource.com/platform/frameworks/support/+archive/$androidxSqlite262Commit/sqlite/sqlite-bundled.tar.gz" `
        -OutFile $androidxArchive
}
if (!(Get-ChildItem -Path $androidxDir -Recurse -Filter "sqlite_bindings.cpp" -ErrorAction SilentlyContinue | Select-Object -First 1)) {
    New-Item -ItemType Directory -Path $androidxDir -Force | Out-Null
    tar -xzf $androidxArchive -C $androidxDir
}

$sqliteObj = Join-Path $WorkDir "sqlite3.o"
$bindingObj = Join-Path $WorkDir "sqlite_bindings.o"
$dll = Join-Path $WorkDir "sqliteJni.dll"
$jni = Join-Path $JdkHome "include"
$jniWin = Join-Path $jni "win32"
$binding = Get-ChildItem -Path $androidxDir -Recurse -Filter "sqlite_bindings.cpp" |
    Select-Object -First 1 -ExpandProperty FullName
if ([string]::IsNullOrWhiteSpace($binding)) {
    throw "sqlite_bindings.cpp was not found in the AndroidX SQLite sources."
}

$sqliteFlags = @(
    "-O3",
    "-DHAVE_USLEEP=1",
    "-DSQLITE_DEFAULT_AUTOVACUUM=1",
    "-DSQLITE_DEFAULT_MEMSTATUS=0",
    "-DSQLITE_DEFAULT_WAL_SYNCHRONOUS=1",
    "-DSQLITE_ENABLE_COLUMN_METADATA",
    "-DSQLITE_ENABLE_FTS3",
    "-DSQLITE_ENABLE_FTS3_PARENTHESIS",
    "-DSQLITE_ENABLE_FTS4",
    "-DSQLITE_ENABLE_FTS5",
    "-DSQLITE_ENABLE_JSON1",
    "-DSQLITE_ENABLE_MATH_FUNCTIONS",
    "-DSQLITE_ENABLE_NORMALIZE",
    "-DSQLITE_ENABLE_RTREE",
    "-DSQLITE_ENABLE_STAT4",
    "-DSQLITE_HAVE_ISNAN",
    "-DSQLITE_OMIT_BUILTIN_TEST",
    "-DSQLITE_OMIT_DEPRECATED",
    "-DSQLITE_OMIT_PROGRESS_CALLBACK",
    "-DSQLITE_OMIT_SHARED_CACHE",
    "-DSQLITE_SECURE_DELETE",
    "-DSQLITE_TEMP_STORE=3",
    "-DSQLITE_THREADSAFE=2"
)

& $clang @sqliteFlags -I $sqliteDir -c (Join-Path $sqliteDir "sqlite3.c") -o $sqliteObj
if ($LASTEXITCODE -ne 0) { throw "Failed to compile sqlite3.c." }

& $clangxx -O3 -Wno-writable-strings -I $sqliteDir -I $jni -I $jniWin -c $binding -o $bindingObj
if ($LASTEXITCODE -ne 0) { throw "Failed to compile sqlite_bindings.cpp." }

& $clangxx -shared $sqliteObj $bindingObj -o $dll
if ($LASTEXITCODE -ne 0) { throw "Failed to link sqliteJni.dll." }

$nativeDir = Join-Path $jarRoot "natives\windows_arm64"
Remove-Item -LiteralPath $jarRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $nativeDir -Force | Out-Null
Copy-Item -LiteralPath $dll -Destination (Join-Path $nativeDir "sqliteJni.dll") -Force

New-Item -ItemType Directory -Path (Split-Path $OutJar) -Force | Out-Null
Remove-Item -LiteralPath $OutJar -Force -ErrorAction SilentlyContinue
Push-Location $jarRoot
try {
    & (Join-Path $JdkHome "bin\jar.exe") cf $OutJar "natives/windows_arm64/sqliteJni.dll"
    if ($LASTEXITCODE -ne 0) { throw "Failed to create $OutJar." }
} finally {
    Pop-Location
}

Get-Item $OutJar
