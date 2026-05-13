param(
    [Parameter(Mandatory = $true)]
    [string]$Repo,

    [Parameter(Mandatory = $true)]
    [string]$Workflow,

    [Parameter(Mandatory = $true)]
    [string]$Ref,

    [string[]]$Field = @(),

    [int]$TimeoutMinutes = 300,

    [int]$PollIntervalSeconds = 30
)

$ErrorActionPreference = "Stop"

$startedAt = (Get-Date).ToUniversalTime().AddSeconds(-10)
$args = @("workflow", "run", $Workflow, "--repo", $Repo, "--ref", $Ref)
foreach ($item in $Field) {
    $args += @("-f", $item)
}

$dispatchOutput = gh @args 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Failed to dispatch $Repo $Workflow on $Ref. Make sure the workflow has workflow_dispatch enabled. $dispatchOutput"
}
if ($dispatchOutput) {
    Write-Host $dispatchOutput
}

$run = $null
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Seconds 10
    $runs = gh run list `
        --repo $Repo `
        --workflow $Workflow `
        --branch $Ref `
        --event workflow_dispatch `
        --limit 20 `
        --json databaseId,createdAt,status,headBranch |
        ConvertFrom-Json

    $run = $runs |
        Where-Object { [DateTime]::Parse($_.createdAt).ToUniversalTime() -ge $startedAt } |
        Sort-Object createdAt -Descending |
        Select-Object -First 1

    if ($null -ne $run) {
        break
    }
}

if ($null -eq $run) {
    throw "Dispatched $Repo $Workflow, but could not find the workflow_dispatch run."
}

$url = "https://github.com/$Repo/actions/runs/$($run.databaseId)"
Write-Host "Watching $Repo run $($run.databaseId): $url"

$deadline = (Get-Date).AddMinutes($TimeoutMinutes)
do {
    $current = gh run view $run.databaseId `
        --repo $Repo `
        --json status,conclusion |
        ConvertFrom-Json

    if ($current.status -eq "completed") {
        if ($current.conclusion -ne "success") {
            throw "$Repo run $($run.databaseId) completed with conclusion '$($current.conclusion)': $url"
        }

        $run.databaseId
        return
    }

    Start-Sleep -Seconds $PollIntervalSeconds
} while ((Get-Date) -lt $deadline)

throw "$Repo run $($run.databaseId) did not complete within $TimeoutMinutes minutes: $url"
