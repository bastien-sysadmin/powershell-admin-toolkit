<#
.SYNOPSIS
    Génère un rapport système de base

.DESCRIPTION
    Ce script récupère plusieurs informations utiles sur un poste Windows :
    nom de la machine, utilisateur connecté, version de Windows, uptime,
    processeur, mémoire RAM et espace disque.

.NOTES
    Auteur : BERTRAND Bastien
    Usage  : Exemple de script d'administration PowerShell
#>

Clear-Host

Write-Host "=== Rapport système ===" -ForegroundColor Cyan
Write-Host ""

$ComputerName = $env:COMPUTERNAME
$CurrentUser = $env:USERNAME
$OS = Get-CimInstance Win32_OperatingSystem
$CPU = Get-CimInstance Win32_Processor
$RAM = [Math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
$LastBoot = $OS.LastBootUpTime
$Uptime = (Get-Date) - $LastBoot

Write-Host "Nom du poste        : $ComputerName"
Write-Host "Utilisateur         : $CurrentUser"
Write-Host "Système             : $($OS.Caption)"
Write-Host "Version             : $($OS.Version)"
Write-Host "Architecture        : $($OS.OSArchitecture)"
Write-Host "Processeur          : $($CPU.Name)"
Write-Host "Mémoire RAM         : $RAM Go"
Write-Host "Dernier démarrage   : $LastBoot"
Write-Host "Uptime              : $($Uptime.Days) jours, $($Uptime.Hours) heures"
Write-Host ""

Write-Host "=== Espace disque ===" -ForegroundColor Cyan

Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    $SizeGB = [Math]::Round($_.Size / 1GB, 2)
    $FreeGB = [Math]::Round($_.FreeSpace / 1GB, 2)
    $FreePercent = [Math]::Round(($_.FreeSpace / $_.Size) * 100, 2)

    Write-Host "Disque $($_.DeviceID) - Total : $SizeGB Go | Libre : $FreeGB Go | Libre : $FreePercent %"
}

Write-Host ""
Write-Host "Rapport terminé." -ForegroundColor Green
