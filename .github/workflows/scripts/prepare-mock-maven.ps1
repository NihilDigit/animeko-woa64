param(
    [Parameter(Mandatory = $true)]
    [string]$AnitorrentArtifacts,

    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,

    [string]$AnimekoDirectory = "",

    [string]$AnitorrentVersion = ""
)

$ErrorActionPreference = "Stop"

function Read-AnimekoVersions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $versions = @{
        Anitorrent = ""
    }

    $settings = Join-Path $Path "settings.gradle.kts"

    if (Test-Path $settings) {
        $match = Select-String -Path $settings -Pattern 'org\.openani\.anitorrent:catalog:([^"]+)' | Select-Object -First 1
        if ($match) {
            $versions.Anitorrent = $match.Matches[0].Groups[1].Value
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

        [string]$Classifier = "",

        [array]$Dependencies = @()
    )

    $groupPath = $GroupId.Replace(".", [IO.Path]::DirectorySeparatorChar)
    $artifactDir = Join-Path $OutputDirectory (Join-Path $groupPath (Join-Path $ArtifactId $Version))
    New-Item -ItemType Directory -Force -Path $artifactDir | Out-Null

    $suffix = if ($Classifier) { "-$Classifier" } else { "" }
    Copy-Item -LiteralPath $JarPath -Destination (Join-Path $artifactDir "$ArtifactId-$Version$suffix.jar") -Force

    $dependenciesXml = ""
    if ($Dependencies.Count -gt 0) {
        $dependencyItems = foreach ($dependency in $Dependencies) {
@"
    <dependency>
      <groupId>$($dependency.GroupId)</groupId>
      <artifactId>$($dependency.ArtifactId)</artifactId>
      <version>$($dependency.Version)</version>
      <scope>$($dependency.Scope)</scope>
    </dependency>
"@
        }
        $dependenciesXml = @"
  <dependencies>
$($dependencyItems -join "`n")
  </dependencies>
"@
    }

    @"
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>$GroupId</groupId>
  <artifactId>$ArtifactId</artifactId>
  <version>$Version</version>
$dependenciesXml
</project>
"@ | Set-Content -Path (Join-Path $artifactDir "$ArtifactId-$Version.pom") -Encoding utf8
}

Remove-Item -LiteralPath $OutputDirectory -Recurse -Force -ErrorAction SilentlyContinue

if ($AnimekoDirectory) {
    $animekoVersions = Read-AnimekoVersions -Path $AnimekoDirectory
    if (!$AnitorrentVersion) {
        $AnitorrentVersion = $animekoVersions.Anitorrent
    }
}

if (!$AnitorrentVersion) {
    throw "AnitorrentVersion was not provided and could not be read from AnimekoDirectory."
}

$anitorrentJar = Get-ChildItem -Path $AnitorrentArtifacts -Recurse -Filter "*windows-arm64*.jar" |
    Select-Object -First 1

if ($null -eq $anitorrentJar) {
    throw "Could not find anitorrent Windows ARM64 jar in $AnitorrentArtifacts."
}

Write-MavenArtifact `
    -GroupId "org.openani.anitorrent" `
    -ArtifactId "anitorrent-native-desktop" `
    -Version $AnitorrentVersion `
    -JarPath $anitorrentJar.FullName `
    -Dependencies @(@{
        GroupId = "org.openani.anitorrent"
        ArtifactId = "anitorrent-native-desktop-jni"
        Version = $AnitorrentVersion
        Scope = "compile"
    })

Write-MavenArtifact `
    -GroupId "org.openani.anitorrent" `
    -ArtifactId "anitorrent-native-desktop" `
    -Version $AnitorrentVersion `
    -JarPath $anitorrentJar.FullName `
    -Classifier "windows-arm64" `
    -Dependencies @(@{
        GroupId = "org.openani.anitorrent"
        ArtifactId = "anitorrent-native-desktop-jni"
        Version = $AnitorrentVersion
        Scope = "compile"
    })
