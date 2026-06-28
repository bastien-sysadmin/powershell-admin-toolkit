<#
.SYNOPSIS
    Teste les ports TCP et UDP utilisés par un environnement Ivanti / LANDesk.

.DESCRIPTION
    Ce script permet de tester rapidement la connectivité réseau vers un poste client,
    un serveur Core ou une passerelle CSA/Tunnel.

    Il propose deux profils de ports :
    - Client     : ports généralement testés depuis ou vers un poste client
    - CoreServer : ports généralement testés depuis ou vers un serveur Core

    Le script peut tester :
    - uniquement les ports TCP
    - uniquement les ports UDP
    - les ports TCP et UDP

    Les résultats sont affichés dans la console et exportés dans un rapport CSV et HTML.

.PARAM Target
    Nom DNS ou adresse IP de la machine à tester.

.PARAM Profile
    Profil de ports à utiliser.
    Valeurs possibles : Client, CoreServer.
    Par défaut : Client.

.PARAM Protocol
    Protocole à tester.
    Valeurs possibles : TCP, UDP, All.
    Par défaut : All.

.PARAM OutputDirectory
    Dossier dans lequel les rapports CSV et HTML seront générés.
    Par défaut : Reports dans le dossier courant.

.PARAM TimeoutMilliseconds
    Délai d'attente en millisecondes pour chaque test de port.
    Par défaut : 1800.

.PARAM OpenReport
    Ouvre automatiquement le rapport HTML à la fin de l'exécution.

.EX
    .\Test-IvantiPorts.ps1 -Target "srv-core-01" -Profile CoreServer -Protocol All

    Teste les ports TCP et UDP du profil CoreServer vers la machine srv-core-01.

.EX
    .\Test-IvantiPorts.ps1 -Target "pc-client-01" -Profile Client -Protocol TCP -OpenReport

    Teste uniquement les ports TCP du profil Client vers pc-client-01 et ouvre le rapport HTML.

.NOTES
    Auteur : BERTRAND Bastien
    Usage  : Exemple de script d'administration PowerShell
    Projet : Test de connectivité des ports Ivanti / LANDesk

#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Target,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Client", "CoreServer")]
    [string]$Profile = "Client",

    [Parameter(Mandatory = $false)]
    [ValidateSet("TCP", "UDP", "All")]
    [string]$Protocol = "All",

    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "Reports",

    [Parameter(Mandatory = $false)]
    [ValidateRange(500, 30000)]
    [int]$TimeoutMilliseconds = 1800,

    [Parameter(Mandatory = $false)]
    [switch]$OpenReport
)

function Resolve-OutputDirectory {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }

    return (Join-Path -Path (Get-Location).Path -ChildPath $Path)
}

function ConvertTo-SafeFileName {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $InvalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $SafeValue = $Value

    foreach ($Char in $InvalidChars) {
        $SafeValue = $SafeValue.Replace($Char, "_")
    }

    return $SafeValue
}

function Test-TcpPort {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $true)]
        [int]$Timeout
    )

    $TcpClient = New-Object System.Net.Sockets.TcpClient
    $Status = "Closed or filtered"
    $Detail = "Connection failed or timed out"

    try {
        $AsyncResult = $TcpClient.BeginConnect($ComputerName, $Port, $null, $null)
        $WaitResult = $AsyncResult.AsyncWaitHandle.WaitOne($Timeout, $false)

        if ($WaitResult) {
            try {
                $TcpClient.EndConnect($AsyncResult)
                $Status = "Open"
                $Detail = "TCP connection established"
            }
            catch {
                $Status = "Closed or filtered"
                $Detail = $_.Exception.Message
            }
        }
        else {
            $Status = "Closed or filtered"
            $Detail = "Connection timed out"
        }
    }
    catch {
        $Status = "Error"
        $Detail = $_.Exception.Message
    }
    finally {
        $TcpClient.Close()
    }

    [PSCustomObject]@{
        Target   = $ComputerName
        Profile  = $Profile
        Protocol = "TCP"
        Port     = $Port
        Status   = $Status
        Detail   = $Detail
        TestedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

function Test-UdpPort {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $true)]
        [int]$Timeout
    )

    $UdpClient = New-Object System.Net.Sockets.UdpClient
    $Status = "No response"
    $Detail = "No UDP response received. The port may be open, filtered, or not responding."
    $Bytes = [System.Text.Encoding]::ASCII.GetBytes("Port test")

    try {
        $UdpClient.Client.ReceiveTimeout = $Timeout
        $UdpClient.Connect($ComputerName, $Port)
        [void]$UdpClient.Send($Bytes, $Bytes.Length)

        $RemoteEndpoint = New-Object System.Net.IPEndPoint([System.Net.IPAddress]::Any, 0)

        try {
            [void]$UdpClient.Receive([ref]$RemoteEndpoint)
            $Status = "Open"
            $Detail = "UDP response received"
        }
        catch [System.Net.Sockets.SocketException] {
            $Status = "No response"
            $Detail = "No UDP response received. The port may be open, filtered, or not responding."
        }
    }
    catch {
        $Status = "Error"
        $Detail = $_.Exception.Message
    }
    finally {
        $UdpClient.Close()
    }

    [PSCustomObject]@{
        Target   = $ComputerName
        Profile  = $Profile
        Protocol = "UDP"
        Port     = $Port
        Status   = $Status
        Detail   = $Detail
        TestedAt = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
}

$PortProfiles = @{
    Client = @{
        TCP = @(80, 137, 139, 443, 445, 4343, 44345, 5007, 9594, 9595, 9982, 12175, 12176, 16992, 16993, 16994, 33354)
        UDP = @(67, 69, 1759, 4011, 9535, 9595, 38293)
    }
    CoreServer = @{
        TCP = @(25, 137, 139, 443, 445, 4343, 44343, 44344, 44346, 9535, 9593, 9594, 9595, 9971, 9972, 12174, 16992, 16993, 16994, 33354)
        UDP = @(68, 1758, 9535, 9595, 33354, 33355, 38293)
    }
}

Clear-Host

if (-not $Target -or $Target.Trim() -eq "") {
    $Target = Read-Host "Veuillez saisir le nom DNS ou l'adresse IP de la machine à tester"
}

if (-not $Target -or $Target.Trim() -eq "") {
    Write-Host "Aucune cible n'a été renseignée. Arrêt du script." -ForegroundColor Red
    exit 1
}

$ResolvedOutputDirectory = Resolve-OutputDirectory -Path $OutputDirectory

if (-not (Test-Path -Path $ResolvedOutputDirectory)) {
    New-Item -Path $ResolvedOutputDirectory -ItemType Directory -Force | Out-Null
}

$DateString = (Get-Date).ToString("yyyyMMdd-HHmmss")
$SafeTarget = ConvertTo-SafeFileName -Value $Target
$CsvReportPath = Join-Path -Path $ResolvedOutputDirectory -ChildPath "IvantiPortTest-$SafeTarget-$Profile-$DateString.csv"
$HtmlReportPath = Join-Path -Path $ResolvedOutputDirectory -ChildPath "IvantiPortTest-$SafeTarget-$Profile-$DateString.html"

Write-Host "=== Test des ports Ivanti / LANDesk ===" -ForegroundColor Cyan
Write-Host "Cible    : $Target"
Write-Host "Profil   : $Profile"
Write-Host "Protocole: $Protocol"
Write-Host "Timeout  : $TimeoutMilliseconds ms"
Write-Host ""

$Results = @()

if ($Protocol -eq "TCP" -or $Protocol -eq "All") {
    Write-Host "Test des ports TCP..." -ForegroundColor Yellow

    foreach ($Port in $PortProfiles[$Profile].TCP) {
        $Result = Test-TcpPort -ComputerName $Target -Port $Port -Timeout $TimeoutMilliseconds
        $Results += $Result

        if ($Result.Status -eq "Open") {
            Write-Host "TCP $Port : Open" -ForegroundColor Green
        }
        else {
            Write-Host "TCP $Port : $($Result.Status)" -ForegroundColor Red
        }
    }

    Write-Host ""
}

if ($Protocol -eq "UDP" -or $Protocol -eq "All") {
    Write-Host "Test des ports UDP..." -ForegroundColor Yellow

    foreach ($Port in $PortProfiles[$Profile].UDP) {
        $Result = Test-UdpPort -ComputerName $Target -Port $Port -Timeout $TimeoutMilliseconds
        $Results += $Result

        if ($Result.Status -eq "Open") {
            Write-Host "UDP $Port : Open" -ForegroundColor Green
        }
        elseif ($Result.Status -eq "No response") {
            Write-Host "UDP $Port : No response" -ForegroundColor Yellow
        }
        else {
            Write-Host "UDP $Port : $($Result.Status)" -ForegroundColor Red
        }
    }

    Write-Host ""
}

$TotalPorts = $Results.Count
$OpenPorts = ($Results | Where-Object { $_.Status -eq "Open" }).Count
$ClosedOrFilteredPorts = ($Results | Where-Object { $_.Status -eq "Closed or filtered" }).Count
$NoResponsePorts = ($Results | Where-Object { $_.Status -eq "No response" }).Count
$ErrorPorts = ($Results | Where-Object { $_.Status -eq "Error" }).Count

$Results | Export-Csv -Path $CsvReportPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"

$HtmlStyle = @"
<style>
body { font-family: Arial, sans-serif; background-color: #f4f4f4; color: #333; margin: 20px; }
h1 { color: #222; }
.summary { display: flex; gap: 15px; flex-wrap: wrap; margin-bottom: 20px; }
.card { background: #fff; border: 1px solid #ddd; border-radius: 8px; padding: 12px; min-width: 160px; box-shadow: 0 2px 4px rgba(0,0,0,0.08); }
table { width: 100%; border-collapse: collapse; background-color: #fff; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #2f6f9f; color: white; }
tr:nth-child(even) { background-color: #f2f2f2; }
.open { color: green; font-weight: bold; }
.closed { color: red; font-weight: bold; }
.warning { color: #b36b00; font-weight: bold; }
.error { color: red; font-weight: bold; }
footer { margin-top: 25px; font-size: 12px; color: #777; }
</style>
"@

$Rows = foreach ($Result in $Results) {
    $StatusClass = switch ($Result.Status) {
        "Open" { "open" }
        "Closed or filtered" { "closed" }
        "No response" { "warning" }
        "Error" { "error" }
        default { "" }
    }

    "<tr><td>$($Result.Target)</td><td>$($Result.Profile)</td><td>$($Result.Protocol)</td><td>$($Result.Port)</td><td class='$StatusClass'>$($Result.Status)</td><td>$($Result.Detail)</td><td>$($Result.TestedAt)</td></tr>"
}

$HtmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<title>Rapport de test des ports Ivanti / LANDesk</title>
$HtmlStyle
</head>
<body>
<h1>Rapport de test des ports Ivanti / LANDesk</h1>

<div class="summary">
    <div class="card"><strong>Cible</strong><br>$Target</div>
    <div class="card"><strong>Profil</strong><br>$Profile</div>
    <div class="card"><strong>Protocole</strong><br>$Protocol</div>
    <div class="card"><strong>Total</strong><br>$TotalPorts</div>
    <div class="card"><strong>Ouverts</strong><br>$OpenPorts</div>
    <div class="card"><strong>Fermés / filtrés</strong><br>$ClosedOrFilteredPorts</div>
    <div class="card"><strong>UDP sans réponse</strong><br>$NoResponsePorts</div>
    <div class="card"><strong>Erreurs</strong><br>$ErrorPorts</div>
</div>

<table>
<thead>
<tr>
<th>Cible</th>
<th>Profil</th>
<th>Protocole</th>
<th>Port</th>
<th>Statut</th>
<th>Détail</th>
<th>Date du test</th>
</tr>
</thead>
<tbody>
$($Rows -join "`n")
</tbody>
</table>

<footer>
Rapport généré le $(Get-Date -Format "dd/MM/yyyy HH:mm:ss") - Script créé par BERTRAND Bastien
</footer>
</body>
</html>
"@

$HtmlContent | Out-File -FilePath $HtmlReportPath -Encoding UTF8

Write-Host "Rapport CSV généré : $CsvReportPath" -ForegroundColor Green
Write-Host "Rapport HTML généré : $HtmlReportPath" -ForegroundColor Green

if ($OpenReport) {
    Start-Process $HtmlReportPath
}

if ($ClosedOrFilteredPorts -gt 0 -or $ErrorPorts -gt 0) {
    exit 1
}

exit 0
