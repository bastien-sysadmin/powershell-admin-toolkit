<#
.SYNOPSIS
    Liste les logiciels installés sur un poste Windows

.DESCRIPTION
    Ce script récupère les logiciels installés depuis les clés de registre Windows
    Il vérifie les emplacements 64 bits, 32 bits et utilisateur courant

    Le script permet également :
    - de filtrer par nom de logiciel
    - d'exporter le résultat en CSV

.PARAM Name
    Permet de filtrer les logiciels par nom.

.PARAM ExportCsv
    Permet d'exporter le résultat dans un fichier CSV.

.PARAM CsvPath
    Chemin du fichier CSV à générer.
    Par défaut : InstalledSoftware.csv

.EX
    .\Get-InstalledSoftware.ps1

.EX
    .\Get-InstalledSoftware.ps1 -Name "Microsoft"

.EX
    .\Get-InstalledSoftware.ps1 -ExportCsv

.EX
    .\Get-InstalledSoftware.ps1 -Name "Microsoft" -ExportCsv -CsvPath ".\MicrosoftSoftware.csv"

.NOTES
    Auteur : BERTRAND Bastien
    Usage  : Exemple de script d'administration PowerShell
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$Name,

    [Parameter(Mandatory = $false)]
    [switch]$ExportCsv,

    [Parameter(Mandatory = $false)]
    [string]$CsvPath = ".\InstalledSoftware.csv"
)

Clear-Host

Write-Host "=== Inventaire des logiciels installés ===" -ForegroundColor Cyan
Write-Host ""

$RegistryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

try {
    $InstalledSoftware = foreach ($Path in $RegistryPaths) {
        if (Test-Path $Path) {
            Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.DisplayName -and
                    $_.DisplayName.Trim() -ne ""
                } |
                Select-Object @{
                    Name = "Nom"
                    Expression = { $_.DisplayName }
                }, @{
                    Name = "Version"
                    Expression = { $_.DisplayVersion }
                }, @{
                    Name = "Editeur"
                    Expression = { $_.Publisher }
                }, @{
                    Name = "DateInstallation"
                    Expression = {
                        if ($_.InstallDate -match '^\d{8}$') {
                            try {
                                [datetime]::ParseExact($_.InstallDate, 'yyyyMMdd', $null).ToString('dd/MM/yyyy')
                            }
                            catch {
                                $_.InstallDate
                            }
                        }
                        else {
                            $_.InstallDate
                        }
                    }
                }, @{
                    Name = "EmplacementInstallation"
                    Expression = { $_.InstallLocation }
                }
        }
    }

    $InstalledSoftware = $InstalledSoftware |
        Sort-Object Nom -Unique

    if ($Name) {
        $InstalledSoftware = $InstalledSoftware |
            Where-Object { $_.Nom -like "*$Name*" }
    }

    if (-not $InstalledSoftware) {
        Write-Warning "Aucun logiciel trouvé avec les critères indiqués."
        exit 1
    }

    $InstalledSoftware | Format-Table -AutoSize

    Write-Host ""
    Write-Host "Nombre de logiciels trouvés : $($InstalledSoftware.Count)" -ForegroundColor Green

    if ($ExportCsv) {
        $InstalledSoftware |
            Export-Csv -Path $CsvPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"

        Write-Host "Export CSV généré : $CsvPath" -ForegroundColor Green
    }

    exit 0
}
catch {
    Write-Host "Une erreur est survenue lors de la récupération des logiciels installés." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
