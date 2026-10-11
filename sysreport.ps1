# quick system health report for windows boxes
param(
    [string]$Out,
    [int]$Warn = 90
)

function Header($name) { "`n== $name ==" }

function Report {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

    Header "system"
    "host:    $env:COMPUTERNAME"
    "os:      $($os.Caption) $($os.Version)"
    "uptime:  $([int]((Get-Date) - $os.LastBootUpTime).TotalHours) hours"

    Header "cpu / memory"
    "cpu:     $($cpu.Name.Trim())"
    "cores:   $($cpu.NumberOfLogicalProcessors)"
    "load:    $($cpu.LoadPercentage)%"
    $total = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $used = [math]::Round(($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / 1MB, 1)
    "mem:     $used GB used / $total GB"

    Header "disk"
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
        $pct = [math]::Round(($_.Size - $_.FreeSpace) / $_.Size * 100)
        $flag = if ($pct -ge $Warn) { "  <-- low space" } else { "" }
        "{0}  {1,6} GB free  {2,3}% used{3}" -f $_.DeviceID, [math]::Round($_.FreeSpace / 1GB, 1), $pct, $flag
    }

    Header "network"
    Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | ForEach-Object {
        "adapter: $($_.InterfaceAlias)"
        "ip:      $($_.IPv4Address.IPAddress)"
        "gateway: $($_.IPv4DefaultGateway.NextHop)"
        "dns:     $($_.DNSServer.ServerAddresses -join ' ')"
    }
    "ping:    $(if (Test-Connection 1.1.1.1 -Count 1 -Quiet) { 'ok' } else { 'FAILED' })"
    "resolve: $(if (Resolve-DnsName github.com -ErrorAction SilentlyContinue) { 'ok' } else { 'FAILED' })"

    Header "top memory"
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 |
        Format-Table Id, ProcessName, @{n='MemMB'; e={[math]::Round($_.WorkingSet64 / 1MB)}} -AutoSize | Out-String

    Header "stopped auto services"
    $stopped = Get-CimInstance Win32_Service -Filter "StartMode='Auto' AND State='Stopped'" | Select-Object -ExpandProperty Name
    if ($stopped) { $stopped } else { "none" }

    Header "recent errors"
    Get-WinEvent -FilterHashtable @{LogName='System'; Level=2} -MaxEvents 10 -ErrorAction SilentlyContinue |
        Format-Table TimeCreated, ProviderName, Id -AutoSize | Out-String
}

if ($Out) {
    Report | Tee-Object -FilePath $Out
    "`nsaved to $Out"
} else {
    Report
}
