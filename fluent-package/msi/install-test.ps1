$ErrorActionPreference = 'Stop'

$msi = ((Get-Item "C:\\fluentd\\fluent-package\\msi\\repositories\\fluent-package-*.msi") | Sort-Object -Descending { $_.LastWriteTime } | Select-Object -First 1).FullName
Write-Host "Installing ${msi} ..."

Start-Process msiexec -ArgumentList "/i", $msi, "/quiet" -Wait -NoNewWindow
$initialStatus = (Get-Service fluentdwinsvc).Status
if ($initialStatus -ne "Stopped") {
    Write-Host "The initial status must be 'Stopped', but it was '${initialStatus}'."
    [Environment]::Exit(1)
}

$ENV:PATH="C:\\opt\\fluent\\bin;" + $ENV:PATH
$ENV:PATH="C:\\opt\\fluent;" + $ENV:PATH

td-agent --version

Write-Host "Measuring times to start the service..."
$timeSpans = 0..2 | % {
    Measure-Command { Start-Service fluentdwinsvc }
    Start-Sleep 15 | Out-Null
    Stop-Service fluentdwinsvc | Out-Null
    Start-Sleep 15 | Out-Null
}
$timeSpans | %{ Write-Host $_.TotalSeconds }
if (($timeSpans | Measure-Object -Property TotalSeconds -Maximum).Maximum -gt 10) {
    Write-Host "Launching is abnormally slow:"
    # $timeSpans | %{ Write-Host $_.TotalSeconds }
    [Environment]::Exit(1)
}

Get-ChildItem "C:\\opt\\fluent\\*.log" | %{
    if (Select-String -Path $_ -Pattern "[warn]", "[error]", "[fatal]" -SimpleMatch -Quiet) {
        Write-Host "There are abnormal level logs in ${_}:"
        Select-String -Path $_ -Pattern "[warn]", "[error]", "[fatal]" -SimpleMatch
        [Environment]::Exit(1)
    }
}

$msi -Match "fluent-package-([0-9\.]+)-.+\.msi"
$name = "Fluent Package v" + $matches[1]
Write-Host "Uninstalling ...${name}"
Get-CimInstance -Class Win32_Product -Filter "Name='${name}'" | Invoke-CimMethod -MethodName Uninstall
$exitcode = $LASTEXITCODE
if ($exitcode -ne 0) {
    [Environment]::Exit($exitcode)
}
Write-Host "Succeeded to uninstall ${name}"

# fluentd.conf should not be removed
$conf = (Get-ChildItem -Path "c:\\opt" -Filter "fluentd.conf" -Recurse -Name)
if ($conf -ne "fluent\etc\fluent\fluentd.conf") {
  Write-Host "Failed to find fluentd.conf: <${conf}>"
  [Environment]::Exit(1)
}
Write-Host "Succeeded to find fluentd.conf"

# fluentd-0.log should not be removed
$conf = (Get-ChildItem -Path "c:\\opt" -Filter "fluentd-0.log" -Recurse -Name)
if ($conf -ne "fluent\fluentd-0.log") {
  Write-Host "Failed to find fluentd-0.log: <${conf}>"
  [Environment]::Exit(1)
}
Write-Host "Succeeded to find fluentd-0.log"
