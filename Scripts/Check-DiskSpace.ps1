<#
.SYNOPSIS
    Vérifie l'espace disque disponible sur les disques locaux

.DESCRIPTION
    Ce script analyse les disques fixes du poste Windows et affiche :
    - la lettre du disque
    - la taille totale
    - l'espace libre
    - le pourcentage d'espace libre
    - un statut OK ou Alerte selon un seuil défini

.PARAMETER ThresholdPercent
    Seuil minimum d'espace libre en pourcentage.
    Par défaut : 15 %

.NOTES
    Auteur : BERTRAND Bastien
    Usage  : Exemple de script d'administration PowerShell
#>

param (
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]$ThresholdPercent = 15
)

Clear-Host

Write-Host "=== Vérification de l'espace disque ===" -ForegroundColor Cyan
Write-Host "Seuil d'alerte : $ThresholdPercent % d'espace libre minimum"
Write-Host ""

try {
    $Disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType = 3"

    if (-not $Disks) {
        Write-Warning "Aucun disque local n'a été trouvé."
        exit 1
    }

    $DiskReport = foreach ($Disk in $Disks) {
        if ($Disk.Size -gt 0) {
            $SizeGB = [Math]::Round($Disk.Size / 1GB, 2)
            $FreeGB = [Math]::Round($Disk.FreeSpace / 1GB, 2)
            $FreePercent = [Math]::Round(($Disk.FreeSpace / $Disk.Size) * 100, 2)

            if ($FreePercent -lt $ThresholdPercent) {
                $Status = "ALERTE"
            }
            else {
                $Status = "OK"
            }

            [PSCustomObject]@{
                Disque              = $Disk.DeviceID
                "Nom du volume"     = $Disk.VolumeName
                "Taille totale GB"  = $SizeGB
                "Espace libre GB"   = $FreeGB
                "Espace libre %"    = $FreePercent
                Statut              = $Status
            }
        }
    }

    $DiskReport | Format-Table -AutoSize

    $AlertDisks = $DiskReport | Where-Object { $_.Statut -eq "ALERTE" }

    if ($AlertDisks) {
        Write-Host ""
        Write-Host "Attention : un ou plusieurs disques sont sous le seuil défini." -ForegroundColor Yellow
        exit 1
    }
    else {
        Write-Host ""
        Write-Host "Tous les disques disposent d'un espace libre suffisant." -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Host "Une erreur est survenue lors de la vérification des disques." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
