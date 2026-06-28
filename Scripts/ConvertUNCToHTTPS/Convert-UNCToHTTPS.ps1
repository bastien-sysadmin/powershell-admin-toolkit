<#
.SYNOPSIS
    Convertit des chemins UNC en chemins HTTPS dans un fichier texte ou un export de packages

.DESCRIPTION
    Ce script lit un fichier d'entrée contenant des chemins UNC, puis remplace ces chemins
    par des chemins HTTPS en convertissant les antislashs Windows en slashs compatibles URL.

    Il génère ensuite :
    - un fichier de sortie contenant les chemins modifiés
    - un fichier de log listant les anciens chemins et les nouveaux chemins générés

    Ce script peut être utile dans un contexte de migration ou d'adaptation de sources
    de déploiement, par exemple lors du passage de chemins réseau UNC vers des URLs HTTPS.

.PARAM InputFile
    Chemin du fichier source à analyser.
    Par défaut : sample-package-export.ldms dans le dossier du script.

.PARAM OutputFile
    Chemin du fichier de sortie généré après conversion.
    Par défaut : converted-package-export.ldms dans le dossier du script.

.PARAM LogFile
    Chemin du fichier de log contenant les modifications effectuées.
    Par défaut : change-log.txt dans le dossier du script.

.EX
    .\Convert-UNCToHTTPS.ps1

    Lance la conversion avec les fichiers par défaut présents dans le dossier du script.

.EX
    .\Convert-UNCToHTTPS.ps1 -InputFile ".\sample-package-export.ldms" -OutputFile ".\converted-package-export.ldms"

    Convertit les chemins UNC du fichier indiqué et génère un nouveau fichier de sortie.

.INPUTS
    Fichier texte, XML ou export applicatif contenant des chemins UNC.

.OUTPUTS
    Fichier modifié avec chemins HTTPS et fichier de log des changements.

.NOTES
    Auteur : BERTRAND Bastien
    Usage  : Exemple de script d'administration PowerShell
    Projet : Conversion de chemins UNC vers HTTPS

#>
```


param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$InputFile = (Join-Path -Path $PSScriptRoot -ChildPath "sample-package-export.ldms"),

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFile = (Join-Path -Path $PSScriptRoot -ChildPath "converted-package-export.ldms"),

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$LogFile = (Join-Path -Path $PSScriptRoot -ChildPath "change-log.txt")
)

function Convert-UNCPathToHTTPS {
    param (
        [Parameter(Mandatory = $true)]
        [string]$UNCPath
    )

    return ($UNCPath -replace '^\\\\', 'https://' -replace '\\', '/')
}

Clear-Host

Write-Host "=== Conversion des chemins UNC vers HTTPS ===" -ForegroundColor Cyan
Write-Host "Fichier source : $InputFile"
Write-Host "Fichier sortie : $OutputFile"
Write-Host "Fichier log    : $LogFile"
Write-Host ""

try {
    if (-not (Test-Path -Path $InputFile)) {
        throw "Le fichier source est introuvable : $InputFile"
    }

    $InputDirectory = Split-Path -Path $InputFile -Parent
    $OutputDirectory = Split-Path -Path $OutputFile -Parent
    $LogDirectory = Split-Path -Path $LogFile -Parent

    foreach ($Directory in @($InputDirectory, $OutputDirectory, $LogDirectory)) {
        if ($Directory -and -not (Test-Path -Path $Directory)) {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
        }
    }

    $FileContent = Get-Content -Path $InputFile -Raw -Encoding UTF8

    # Recherche les chemins UNC, par exemple : \\SRV-FILES-01\Packages$\App\install.ps1
    # Le motif s'arrÃªte avant les caractÃ¨res qui terminent gÃ©nÃ©ralement une valeur XML ou HTML.
    $UNCPathPattern = '\\\\[^<>"'']+'
    $UNCPaths = [regex]::Matches($FileContent, $UNCPathPattern) |
        ForEach-Object { $_.Value.Trim() } |
        Sort-Object -Unique

    if (-not $UNCPaths -or $UNCPaths.Count -eq 0) {
        Write-Warning "Aucun chemin UNC n'a Ã©tÃ© trouvÃ© dans le fichier source."
        Set-Content -Path $OutputFile -Value $FileContent -Encoding UTF8
        Set-Content -Path $LogFile -Value "Aucun chemin UNC trouvÃ©. Aucune modification effectuÃ©e." -Encoding UTF8
        exit 0
    }

    $ConvertedContent = $FileContent
    $LogEntries = New-Object System.Collections.Generic.List[string]
    $ModificationDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

    $LogEntries.Add("======================== Log de conversion des chemins ========================")
    $LogEntries.Add("Date et heure de la conversion : $ModificationDate")
    $LogEntries.Add("Fichier source : $InputFile")
    $LogEntries.Add("Fichier sortie : $OutputFile")
    $LogEntries.Add("=============================================================================")
    $LogEntries.Add("")

    $Index = 0
    foreach ($OldPath in $UNCPaths) {
        $Index++
        $NewPath = Convert-UNCPathToHTTPS -UNCPath $OldPath
        $ConvertedContent = $ConvertedContent.Replace($OldPath, $NewPath)

        $LogEntries.Add("[$ModificationDate] Conversion $Index")
        $LogEntries.Add("Ancien chemin : $OldPath")
        $LogEntries.Add("Nouveau chemin : $NewPath")
        $LogEntries.Add("-------------------------------------------------------------")

        $Progress = [Math]::Round(($Index / $UNCPaths.Count) * 100, 0)
        Write-Progress -Activity "Conversion des chemins UNC" -Status "Chemin $Index sur $($UNCPaths.Count)" -PercentComplete $Progress
    }

    Set-Content -Path $OutputFile -Value $ConvertedContent -Encoding UTF8
    Set-Content -Path $LogFile -Value $LogEntries -Encoding UTF8

    Write-Host "Conversion terminÃ©e." -ForegroundColor Green
    Write-Host "Nombre de chemins convertis : $($UNCPaths.Count)" -ForegroundColor Green
    Write-Host "Fichier gÃ©nÃ©rÃ© : $OutputFile" -ForegroundColor Green
    Write-Host "Log gÃ©nÃ©rÃ©     : $LogFile" -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "Une erreur est survenue pendant la conversion." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
