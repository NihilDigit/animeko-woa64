param(
    [Parameter(Mandatory = $true)]
    [string]$AppDirectory,

    [Parameter(Mandatory = $true)]
    [string]$SqliteJniDll
)

$ErrorActionPreference = "Stop"

$jar = Get-ChildItem -LiteralPath $AppDirectory -Filter "sqlite-bundled-jvm-*.jar" |
    Select-Object -First 1

if ($null -eq $jar) {
    throw "Could not find sqlite-bundled-jvm jar under $AppDirectory."
}
if (!(Test-Path -LiteralPath $SqliteJniDll)) {
    throw "Could not find SQLite JNI DLL at $SqliteJniDll."
}

Add-Type -AssemblyName System.IO.Compression.FileSystem

$entryName = "natives/windows_arm64/sqliteJni.dll"
$zip = [System.IO.Compression.ZipFile]::Open($jar.FullName, [System.IO.Compression.ZipArchiveMode]::Update)
try {
    $existing = $zip.GetEntry($entryName)
    if ($null -ne $existing) {
        $existing.Delete()
    }
    [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
        $zip,
        (Resolve-Path -LiteralPath $SqliteJniDll).Path,
        $entryName,
        [System.IO.Compression.CompressionLevel]::Optimal
    ) | Out-Null
}
finally {
    $zip.Dispose()
}

Write-Host "Patched $($jar.Name) with $entryName"
