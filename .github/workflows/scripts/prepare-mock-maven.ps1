param(
    [Parameter(Mandatory = $true)]
    [string]$AnitorrentArtifacts,

    [Parameter(Mandatory = $true)]
    [string]$MediampArtifacts,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$AnimekoDirectory = "",

    [string]$AnitorrentVersion = "",

    [string]$MediampVersion = ""
)

$ErrorActionPreference = "Stop"

function Read-AnimekoVersions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $versions = @{
        Anitorrent = ""
        Mediamp = ""
    }

    $settings = Join-Path $Path "settings.gradle.kts"
    $catalog = Join-Path $Path "gradle/libs.versions.toml"

    if (Test-Path $settings) {
        $match = Select-String -Path $settings -Pattern 'org\.openani\.anitorrent:catalog:([^"]+)' | Select-Object -First 1
        if ($match) {
            $versions.Anitorrent = $match.Matches[0].Groups[1].Value
        }
    }

    if (Test-Path $catalog) {
        $match = Select-String -Path $catalog -Pattern '^mediamp\s*=\s*"([^"]+)"' | Select-Object -First 1
        if ($match) {
            $versions.Mediamp = $match.Matches[0].Groups[1].Value
        }
    }

    $versions
}

function Write-MavenArtifact {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GroupId,

        [Parameter(Mandatory = $true)]
        [string]$ArtifactId,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [string]$JarPath,

        [string]$Classifier = ""
    )

    $groupPath = $GroupId.Replace(".", [IO.Path]::DirectorySeparatorChar)
    $artifactDir = Join-Path $OutputDirectory (Join-Path $groupPath (Join-Path $ArtifactId $Version))
    New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

    $suffix = if ($Classifier) { "-$Classifier" } else { "" }
    Copy-Item -LiteralPath $JarPath -Destination (Join-Path $artifactDir "$ArtifactId-$Version$suffix.jar") -Force

    @"
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>$GroupId</groupId>
  <artifactId>$ArtifactId</artifactId>
  <version>$Version</version>
</project>
"@ | Set-Content -Path (Join-Path $artifactDir "$ArtifactId-$Version.pom") -Encoding utf8
}

Remove-Item -LiteralPath $OutputDirectory -Recurse -Force -ErrorAction SilentlyContinue

if ($AnimekoDirectory) {
    $animekoVersions = Read-AnimekoVersions -Path $AnimekoDirectory
    if (!$AnitorrentVersion) {
        $AnitorrentVersion = $animekoVersions.Anitorrent
    }
    if (!$MediampVersion) {
        $MediampVersion = $animekoVersions.Mediamp
    }
}

if (!$AnitorrentVersion) {
    throw "AnitorrentVersion was not provided and could not be read from AnimekoDirectory."
}
if (!$MediampVersion) {
    throw "MediampVersion was not provided and could not be read from AnimekoDirectory."
}

$anitorrentJar = Get-ChildItem -Path $AnitorrentArtifacts -Recurse -Filter "*windows-arm64*.jar" |
    Select-Object -First 1
$mediampJar = Get-ChildItem -Path $MediampArtifacts -Recurse -Filter "*windows-arm64*.jar" |
    Select-Object -First 1

if ($null -eq $anitorrentJar) {
    throw "Could not find anitorrent Windows ARM64 jar in $AnitorrentArtifacts."
}
if ($null -eq $mediampJar) {
    throw "Could not find mediamp Windows ARM64 jar in $MediampArtifacts."
}

Write-MavenArtifact `
    -GroupId "org.openani.anitorrent" `
    -ArtifactId "anitorrent-native-desktop" `
    -Version $AnitorrentVersion `
    -JarPath $anitorrentJar.FullName

Write-MavenArtifact `
    -GroupId "org.openani.anitorrent" `
    -ArtifactId "anitorrent-native-desktop" `
    -Version $AnitorrentVersion `
    -JarPath $anitorrentJar.FullName `
    -Classifier "windows-arm64"

Write-MavenArtifact `
    -GroupId "org.openani.mediamp" `
    -ArtifactId "mediamp-ffmpeg-runtime-windows-arm64" `
    -Version $MediampVersion `
    -JarPath $mediampJar.FullName
