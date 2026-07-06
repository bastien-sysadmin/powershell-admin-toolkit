<#
.SYNOPSIS
    Audit de securite Windows local.

.DESCRIPTION
    Ce script realise plusieurs controles de securite de base sur un poste ou serveur Windows :
    - Pare-feu Windows
    - Windows Defender
    - UAC
    - BitLocker
    - SMBv1
    - Bureau a distance / NLA
    - Administrateurs locaux
    - Dernieres mises a jour
    - Redemarrage en attente
    - Compte invite local
    - Secure Boot
    - WinRM

.PARAM ExportHtml
    Exporte le rapport au format HTML.

.PARAM ExportCsv
    Exporte le rapport au format CSV.

.PARAM OutputDirectory
    Dossier de sortie pour les exports HTML/CSV.

.EX
    .\Invoke-WindowsSecurityAudit.ps1

.EX
    .\Invoke-WindowsSecurityAudit.ps1 -ExportHtml -ExportCsv

.NOTES
    Auteur : BERTRAND Bastien
    Version : 1.0
#>

[CmdletBinding()]
param(
    [switch]$ExportHtml,
    [switch]$ExportCsv,
    [string]$OutputDirectory = ".\AuditResults"
)

$ErrorActionPreference = "Stop"
$Results = New-Object System.Collections.Generic.List[object]

function Add-AuditResult {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Controle,

        [Parameter(Mandatory = $true)]
        [ValidateSet("OK", "WARNING", "ERROR", "INFO")]
        [string]$Statut,

        [Parameter(Mandatory = $true)]
        [string]$Detail
    )

    $Results.Add([PSCustomObject]@{
        Controle = $Controle
        Statut   = $Statut
        Detail   = $Detail
    })
}

function Test-IsAdministrator {
    try {
        $CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $Principal = New-Object Security.Principal.WindowsPrincipal($CurrentIdentity)
        return $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Write-ResultToConsole {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$AuditResults
    )

    foreach ($Result in $AuditResults) {
        switch ($Result.Statut) {
            "OK"      { $Color = "Green" }
            "WARNING" { $Color = "Yellow" }
            "ERROR"   { $Color = "Red" }
            "INFO"    { $Color = "Cyan" }
            default   { $Color = "White" }
        }

        Write-Host ("[{0,-7}] {1}" -f $Result.Statut, $Result.Controle) -ForegroundColor $Color
        Write-Host ("          {0}" -f $Result.Detail) -ForegroundColor Gray
        Write-Host ""
    }
}

function Get-SafeDate {
    param(
        [Parameter(Mandatory = $false)]
        $DateValue
    )

    if ($null -eq $DateValue -or [string]::IsNullOrWhiteSpace($DateValue.ToString())) {
        return $null
    }

    try {
        return [datetime]$DateValue
    }
    catch {
        return $null
    }
}

Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "     Audit de securite Windows" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

$ComputerName = $env:COMPUTERNAME
$CurrentUser = "$env:USERDOMAIN\$env:USERNAME"
$AuditDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$IsAdmin = Test-IsAdministrator

Write-Host "Machine       : $ComputerName"
Write-Host "Utilisateur   : $CurrentUser"
Write-Host "Date audit    : $AuditDate"
Write-Host "Mode admin    : $IsAdmin"
Write-Host ""

if (-not $IsAdmin) {
    Add-AuditResult -Controle "Droits administrateur" -Statut "INFO" -Detail "Le script n'est pas lance en administrateur. Certains controles peuvent etre limites."
}
else {
    Add-AuditResult -Controle "Droits administrateur" -Statut "OK" -Detail "Le script est lance avec des droits administrateur."
}

# 1. Pare-feu Windows
try {
    $FirewallProfiles = Get-NetFirewallProfile
    $DisabledProfiles = $FirewallProfiles | Where-Object { $_.Enabled -eq $false }

    if ($DisabledProfiles) {
        $DisabledNames = ($DisabledProfiles | Select-Object -ExpandProperty Name) -join ", "
        Add-AuditResult -Controle "Pare-feu Windows" -Statut "WARNING" -Detail "Profil(s) desactive(s) : $DisabledNames."
    }
    else {
        Add-AuditResult -Controle "Pare-feu Windows" -Statut "OK" -Detail "Tous les profils du pare-feu Windows sont actives."
    }
}
catch {
    Add-AuditResult -Controle "Pare-feu Windows" -Statut "ERROR" -Detail "Impossible de verifier le pare-feu Windows. Erreur : $($_.Exception.Message)"
}

# 2. Windows Defender
try {
    if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
        $DefenderStatus = Get-MpComputerStatus

        $Issues = @()

        if (-not $DefenderStatus.AntivirusEnabled) {
            $Issues += "Antivirus desactive"
        }

        if (-not $DefenderStatus.RealTimeProtectionEnabled) {
            $Issues += "Protection temps reel desactivee"
        }

        if (-not $DefenderStatus.AntispywareEnabled) {
            $Issues += "Protection antispyware desactivee"
        }

        if ($Issues.Count -eq 0) {
            Add-AuditResult -Controle "Windows Defender" -Statut "OK" -Detail "Windows Defender est actif avec la protection en temps reel."
        }
        else {
            Add-AuditResult -Controle "Windows Defender" -Statut "WARNING" -Detail ($Issues -join " ; ")
        }
    }
    else {
        Add-AuditResult -Controle "Windows Defender" -Statut "INFO" -Detail "La commande Get-MpComputerStatus n'est pas disponible sur ce systeme."
    }
}
catch {
    Add-AuditResult -Controle "Windows Defender" -Statut "ERROR" -Detail "Impossible de verifier Windows Defender. Erreur : $($_.Exception.Message)"
}

# 3. UAC
try {
    $UacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    $UacValue = Get-ItemProperty -Path $UacPath -Name EnableLUA

    if ($UacValue.EnableLUA -eq 1) {
        Add-AuditResult -Controle "UAC" -Statut "OK" -Detail "Le controle de compte utilisateur est active."
    }
    else {
        Add-AuditResult -Controle "UAC" -Statut "WARNING" -Detail "Le controle de compte utilisateur est desactive."
    }
}
catch {
    Add-AuditResult -Controle "UAC" -Statut "ERROR" -Detail "Impossible de verifier l'UAC. Erreur : $($_.Exception.Message)"
}

# 4. BitLocker sur le disque systeme
try {
    if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
        $SystemDrive = $env:SystemDrive
        $BitLockerVolume = Get-BitLockerVolume -MountPoint $SystemDrive

        if ($BitLockerVolume.ProtectionStatus -eq "On") {
            Add-AuditResult -Controle "BitLocker" -Statut "OK" -Detail "BitLocker est active sur $SystemDrive."
        }
        else {
            Add-AuditResult -Controle "BitLocker" -Statut "WARNING" -Detail "BitLocker n'est pas active sur $SystemDrive. Statut : $($BitLockerVolume.ProtectionStatus)."
        }
    }
    else {
        Add-AuditResult -Controle "BitLocker" -Statut "INFO" -Detail "La commande Get-BitLockerVolume n'est pas disponible sur ce systeme."
    }
}
catch {
    Add-AuditResult -Controle "BitLocker" -Statut "ERROR" -Detail "Impossible de verifier BitLocker. Erreur : $($_.Exception.Message)"
}

# 5. SMBv1
try {
    if (Get-Command Get-SmbServerConfiguration -ErrorAction SilentlyContinue) {
        $SmbConfig = Get-SmbServerConfiguration

        if ($SmbConfig.EnableSMB1Protocol -eq $false) {
            Add-AuditResult -Controle "SMBv1" -Statut "OK" -Detail "SMBv1 est desactive."
        }
        else {
            Add-AuditResult -Controle "SMBv1" -Statut "WARNING" -Detail "SMBv1 est active. Il est recommande de le desactiver."
        }
    }
    else {
        Add-AuditResult -Controle "SMBv1" -Statut "INFO" -Detail "La commande Get-SmbServerConfiguration n'est pas disponible sur ce systeme."
    }
}
catch {
    Add-AuditResult -Controle "SMBv1" -Statut "ERROR" -Detail "Impossible de verifier SMBv1. Erreur : $($_.Exception.Message)"
}

# 6. Bureau a distance et NLA
try {
    $RdpPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
    $RdpValue = Get-ItemProperty -Path $RdpPath -Name fDenyTSConnections

    if ($RdpValue.fDenyTSConnections -eq 0) {
        Add-AuditResult -Controle "Bureau a distance" -Statut "WARNING" -Detail "Le Bureau a distance est active. Verifier que c'est necessaire et securise."
    }
    else {
        Add-AuditResult -Controle "Bureau a distance" -Statut "OK" -Detail "Le Bureau a distance est desactive."
    }
}
catch {
    Add-AuditResult -Controle "Bureau a distance" -Statut "ERROR" -Detail "Impossible de verifier le Bureau a distance. Erreur : $($_.Exception.Message)"
}

try {
    $NlaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
    $NlaValue = Get-ItemProperty -Path $NlaPath -Name UserAuthentication

    if ($NlaValue.UserAuthentication -eq 1) {
        Add-AuditResult -Controle "RDP - NLA" -Statut "OK" -Detail "L'authentification au niveau du reseau est activee."
    }
    else {
        Add-AuditResult -Controle "RDP - NLA" -Statut "WARNING" -Detail "L'authentification au niveau du reseau est desactivee."
    }
}
catch {
    Add-AuditResult -Controle "RDP - NLA" -Statut "ERROR" -Detail "Impossible de verifier l'etat NLA. Erreur : $($_.Exception.Message)"
}

# 7. Administrateurs locaux
try {
    if ((Get-Command Get-LocalGroup -ErrorAction SilentlyContinue) -and (Get-Command Get-LocalGroupMember -ErrorAction SilentlyContinue)) {
        $AdminGroup = Get-LocalGroup -SID "S-1-5-32-544"
        $AdminMembers = Get-LocalGroupMember -Group $AdminGroup.Name

        if ($AdminMembers.Count -gt 0) {
            $AdminList = ($AdminMembers | Select-Object -ExpandProperty Name) -join " ; "
            Add-AuditResult -Controle "Administrateurs locaux" -Statut "INFO" -Detail "Membres du groupe $($AdminGroup.Name) : $AdminList"
        }
        else {
            Add-AuditResult -Controle "Administrateurs locaux" -Statut "WARNING" -Detail "Aucun membre trouve dans le groupe des administrateurs locaux."
        }
    }
    else {
        Add-AuditResult -Controle "Administrateurs locaux" -Statut "INFO" -Detail "Les commandes Get-LocalGroup/Get-LocalGroupMember ne sont pas disponibles."
    }
}
catch {
    Add-AuditResult -Controle "Administrateurs locaux" -Statut "ERROR" -Detail "Impossible de lister les administrateurs locaux. Erreur : $($_.Exception.Message)"
}

# 8. Dernieres mises a jour Windows
try {
    $Hotfixes = Get-HotFix | Where-Object { $_.InstalledOn } | Sort-Object -Property {
        $Date = Get-SafeDate $_.InstalledOn
        if ($Date) { $Date } else { [datetime]"1900-01-01" }
    } -Descending

    $LastHotfix = $Hotfixes | Select-Object -First 1
    $LastFiveHotfixes = $Hotfixes | Select-Object -First 5

    if ($LastHotfix) {
        $LastDate = Get-SafeDate $LastHotfix.InstalledOn
        $LastDateText = if ($LastDate) { $LastDate.ToString("yyyy-MM-dd") } else { "Date inconnue" }
        $DaysSinceLastUpdate = if ($LastDate) { (New-TimeSpan -Start $LastDate -End (Get-Date)).Days } else { $null }

        if ($null -ne $DaysSinceLastUpdate -and $DaysSinceLastUpdate -le 45) {
            Add-AuditResult -Controle "Mises a jour Windows" -Statut "OK" -Detail "Dernier correctif installe : $($LastHotfix.HotFixID) le $LastDateText."
        }
        else {
            Add-AuditResult -Controle "Mises a jour Windows" -Statut "WARNING" -Detail "Dernier correctif installe : $($LastHotfix.HotFixID) le $LastDateText. Verifier si le poste est a jour."
        }

        $LastFiveText = ($LastFiveHotfixes | ForEach-Object {
            $Date = Get-SafeDate $_.InstalledOn
            $DateText = if ($Date) { $Date.ToString("yyyy-MM-dd") } else { "Date inconnue" }
            "$($_.HotFixID) ($DateText)"
        }) -join " ; "

        Add-AuditResult -Controle "Derniers correctifs" -Statut "INFO" -Detail $LastFiveText
    }
    else {
        Add-AuditResult -Controle "Mises a jour Windows" -Statut "WARNING" -Detail "Aucun correctif trouve via Get-HotFix."
    }
}
catch {
    Add-AuditResult -Controle "Mises a jour Windows" -Statut "ERROR" -Detail "Impossible de recuperer les correctifs Windows. Erreur : $($_.Exception.Message)"
}

# 9. Redemarrage en attente
try {
    $PendingRebootReasons = @()

    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending") {
        $PendingRebootReasons += "Component Based Servicing"
    }

    if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired") {
        $PendingRebootReasons += "Windows Update"
    }

    $SessionManagerPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager"
    $SessionManager = Get-ItemProperty -Path $SessionManagerPath -ErrorAction SilentlyContinue

    if ($SessionManager.PendingFileRenameOperations) {
        $PendingRebootReasons += "PendingFileRenameOperations"
    }

    if ($PendingRebootReasons.Count -gt 0) {
        Add-AuditResult -Controle "Redemarrage en attente" -Statut "WARNING" -Detail "Un redemarrage est necessaire. Raison(s) : $($PendingRebootReasons -join ', ')."
    }
    else {
        Add-AuditResult -Controle "Redemarrage en attente" -Statut "OK" -Detail "Aucun redemarrage en attente detecte."
    }
}
catch {
    Add-AuditResult -Controle "Redemarrage en attente" -Statut "ERROR" -Detail "Impossible de verifier le redemarrage en attente. Erreur : $($_.Exception.Message)"
}

# 10. Compte invite local
try {
    if (Get-Command Get-LocalUser -ErrorAction SilentlyContinue) {
        $GuestAccount = Get-LocalUser | Where-Object { $_.SID.Value -match "-501$" }

        if ($GuestAccount) {
            if ($GuestAccount.Enabled -eq $false) {
                Add-AuditResult -Controle "Compte invite local" -Statut "OK" -Detail "Le compte invite local '$($GuestAccount.Name)' est desactive."
            }
            else {
                Add-AuditResult -Controle "Compte invite local" -Statut "WARNING" -Detail "Le compte invite local '$($GuestAccount.Name)' est active."
            }
        }
        else {
            Add-AuditResult -Controle "Compte invite local" -Statut "INFO" -Detail "Compte invite local introuvable."
        }
    }
    else {
        Add-AuditResult -Controle "Compte invite local" -Statut "INFO" -Detail "La commande Get-LocalUser n'est pas disponible sur ce systeme."
    }
}
catch {
    Add-AuditResult -Controle "Compte invite local" -Statut "ERROR" -Detail "Impossible de verifier le compte invite local. Erreur : $($_.Exception.Message)"
}

# 11. Secure Boot
try {
    if (Get-Command Confirm-SecureBootUEFI -ErrorAction SilentlyContinue) {
        $SecureBoot = Confirm-SecureBootUEFI

        if ($SecureBoot -eq $true) {
            Add-AuditResult -Controle "Secure Boot" -Statut "OK" -Detail "Secure Boot est active."
        }
        else {
            Add-AuditResult -Controle "Secure Boot" -Statut "WARNING" -Detail "Secure Boot est desactive."
        }
    }
    else {
        Add-AuditResult -Controle "Secure Boot" -Statut "INFO" -Detail "La commande Confirm-SecureBootUEFI n'est pas disponible sur ce systeme."
    }
}
catch {
    Add-AuditResult -Controle "Secure Boot" -Statut "INFO" -Detail "Impossible de verifier Secure Boot. Le systeme peut etre en BIOS herite ou ne pas supporter cette verification."
}

# 12. WinRM
try {
    $WinRmService = Get-Service -Name WinRM -ErrorAction Stop

    if ($WinRmService.Status -eq "Running") {
        Add-AuditResult -Controle "WinRM" -Statut "INFO" -Detail "Le service WinRM est demarre. Verifier que l'acces distant est attendu et filtre."
    }
    else {
        Add-AuditResult -Controle "WinRM" -Statut "OK" -Detail "Le service WinRM n'est pas demarre."
    }
}
catch {
    Add-AuditResult -Controle "WinRM" -Statut "ERROR" -Detail "Impossible de verifier WinRM. Erreur : $($_.Exception.Message)"
}

# 13. Politique d'execution PowerShell
try {
    $ExecutionPolicy = Get-ExecutionPolicy -Scope LocalMachine

    if ($ExecutionPolicy -in @("Restricted", "RemoteSigned", "AllSigned")) {
        Add-AuditResult -Controle "Execution Policy PowerShell" -Statut "OK" -Detail "Politique d'execution LocalMachine : $ExecutionPolicy."
    }
    elseif ($ExecutionPolicy -in @("Unrestricted", "Bypass")) {
        Add-AuditResult -Controle "Execution Policy PowerShell" -Statut "WARNING" -Detail "Politique d'execution permissive : $ExecutionPolicy."
    }
    else {
        Add-AuditResult -Controle "Execution Policy PowerShell" -Statut "INFO" -Detail "Politique d'execution LocalMachine : $ExecutionPolicy."
    }
}
catch {
    Add-AuditResult -Controle "Execution Policy PowerShell" -Statut "ERROR" -Detail "Impossible de verifier l'Execution Policy. Erreur : $($_.Exception.Message)"
}

# Affichage console
Write-Host "Resultats de l'audit" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

Write-ResultToConsole -AuditResults $Results

# Resume
$OkCount = ($Results | Where-Object { $_.Statut -eq "OK" }).Count
$WarningCount = ($Results | Where-Object { $_.Statut -eq "WARNING" }).Count
$ErrorCount = ($Results | Where-Object { $_.Statut -eq "ERROR" }).Count
$InfoCount = ($Results | Where-Object { $_.Statut -eq "INFO" }).Count

Write-Host "Resume" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "OK       : $OkCount" -ForegroundColor Green
Write-Host "WARNING  : $WarningCount" -ForegroundColor Yellow
Write-Host "ERROR    : $ErrorCount" -ForegroundColor Red
Write-Host "INFO     : $InfoCount" -ForegroundColor Cyan
Write-Host ""

# Exports
if ($ExportHtml -or $ExportCsv) {
    try {
        if (-not (Test-Path $OutputDirectory)) {
            New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        }

        $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $BaseFileName = "WindowsSecurityAudit-$ComputerName-$Timestamp"

        if ($ExportCsv) {
            $CsvPath = Join-Path $OutputDirectory "$BaseFileName.csv"
            $Results | Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
            Write-Host "Export CSV genere : $CsvPath" -ForegroundColor Green
        }

        if ($ExportHtml) {
            $HtmlPath = Join-Path $OutputDirectory "$BaseFileName.html"

            $Rows = foreach ($Result in $Results) {
                $CssClass = $Result.Statut.ToLower()
                "<tr><td>$($Result.Controle)</td><td class='$CssClass'>$($Result.Statut)</td><td>$($Result.Detail)</td></tr>"
            }

            $HtmlContent = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Audit de securite Windows - $ComputerName</title>
    <style>
        body {
            font-family: Segoe UI, Arial, sans-serif;
            background-color: #f4f6f8;
            color: #1f2937;
            margin: 30px;
        }
        .container {
            background: #ffffff;
            border-radius: 12px;
            padding: 25px;
            box-shadow: 0 4px 16px rgba(0,0,0,0.08);
        }
        h1 {
            margin-top: 0;
            color: #111827;
        }
        .meta {
            margin-bottom: 20px;
            padding: 15px;
            background: #f9fafb;
            border-left: 4px solid #2563eb;
        }
        .summary {
            display: flex;
            gap: 12px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        .card {
            padding: 12px 16px;
            border-radius: 10px;
            background: #f9fafb;
            min-width: 110px;
            font-weight: 600;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            overflow: hidden;
            border-radius: 10px;
        }
        th {
            background-color: #111827;
            color: white;
            text-align: left;
            padding: 12px;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #e5e7eb;
            vertical-align: top;
        }
        tr:hover {
            background-color: #f9fafb;
        }
        .ok {
            color: #15803d;
            font-weight: bold;
        }
        .warning {
            color: #a16207;
            font-weight: bold;
        }
        .error {
            color: #b91c1c;
            font-weight: bold;
        }
        .info {
            color: #0369a1;
            font-weight: bold;
        }
        footer {
            margin-top: 25px;
            color: #6b7280;
            font-size: 12px;
        }
    </style>
</head>
<body>
<div class="container">
    <h1>Audit de securite Windows</h1>

    <div class="meta">
        <div><strong>Machine :</strong> $ComputerName</div>
        <div><strong>Utilisateur :</strong> $CurrentUser</div>
        <div><strong>Date :</strong> $AuditDate</div>
        <div><strong>Mode administrateur :</strong> $IsAdmin</div>
    </div>

    <div class="summary">
        <div class="card ok">OK : $OkCount</div>
        <div class="card warning">WARNING : $WarningCount</div>
        <div class="card error">ERROR : $ErrorCount</div>
        <div class="card info">INFO : $InfoCount</div>
    </div>

    <table>
        <thead>
            <tr>
                <th>Controle</th>
                <th>Statut</th>
                <th>Detail</th>
            </tr>
        </thead>
        <tbody>
            $($Rows -join "`n")
        </tbody>
    </table>

    <footer>
        Rapport genere par Invoke-WindowsSecurityAudit.ps1
    </footer>
</div>
</body>
</html>
"@

            $HtmlContent | Out-File -FilePath $HtmlPath -Encoding UTF8
            Write-Host "Export HTML genere : $HtmlPath" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "Erreur lors de l'export : $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Audit termine." -ForegroundColor Cyan
