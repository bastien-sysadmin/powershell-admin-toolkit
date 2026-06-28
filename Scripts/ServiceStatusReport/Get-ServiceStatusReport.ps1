<#
.SYNOPSIS
    Vérifie l'état de services Windows à partir d'un fichier CSV et génère un rapport HTML

.DESCRIPTION
    Ce script lit un fichier CSV contenant une liste de services à contrôler, puis vérifie
    leur présence, leur état et leur type de démarrage sur le poste ou serveur Windows.

    Pour chaque service, le script récupère :
    - le nom technique du service ;
    - le nom d'affichage ;
    - l'état du service : Running, Stopped ou NotFound ;
    - le type de démarrage : Auto, Manual, Disabled ou Unknown.

    Le script génère ensuite un rapport HTML lisible contenant un résumé global et un tableau
    détaillé des services contrôlés.

.PARAM ServiceListCsv
    Chemin du fichier CSV contenant la liste des services à vérifier.
    Le fichier doit contenir une colonne nommée "ServiceName".

    Par défaut : sample-services.csv dans le dossier du script.

.PARAM OutputHtml
    Chemin du rapport HTML généré.

    Par défaut : Report-ServiceStatus.html dans le dossier du script.

.PARAM OpenReport
    Ouvre automatiquement le rapport HTML dans le navigateur par défaut après génération.

.EX
    .\Get-ServiceStatusReport.ps1

    Vérifie les services listés dans le fichier sample-services.csv et génère un rapport HTML.

.EX
    .\Get-ServiceStatusReport.ps1 -ServiceListCsv ".\sample-ivanti-services.csv" -OutputHtml ".\Report-IvantiServices.html" -OpenReport

    Vérifie les services listés dans le fichier indiqué, génère un rapport HTML personnalisé
    et l'ouvre automatiquement dans le navigateur par défaut.

.INPUTS
    Fichier CSV contenant une colonne "ServiceName".

.OUTPUTS
    Rapport HTML contenant l'état des services contrôlés.

.NOTES
    Auteur : BERTRAND Bastien
    Usage  : Exemple de script d'administration PowerShell
    Projet : Vérification de services Windows et génération de rapport HTML
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ServiceListCsv = (Join-Path -Path $PSScriptRoot -ChildPath "sample-services.csv"),

    [Parameter(Mandatory = $false)]
    [string]$OutputHtml = (Join-Path -Path $PSScriptRoot -ChildPath "Report-ServiceStatus.html"),

    [Parameter(Mandatory = $false)]
    [switch]$OpenReport
)

function ConvertTo-HtmlText {
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [object]$Value
    )

    if ($null -eq $Value) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

function Get-MatchingService {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $true)]
        [array]$WindowsServices
    )

    $cleanName = $ServiceName.Trim()

    $match = $WindowsServices | Where-Object {
        $_.Name -eq $cleanName -or $_.DisplayName -eq $cleanName
    } | Select-Object -First 1

    return $match
}

try {
    if (-not (Test-Path -Path $ServiceListCsv)) {
        throw "Le fichier CSV est introuvable : $ServiceListCsv"
    }

    $serviceList = Import-Csv -Path $ServiceListCsv

    if (-not $serviceList) {
        throw "Le fichier CSV est vide : $ServiceListCsv"
    }

    if (-not ($serviceList[0].PSObject.Properties.Name -contains "ServiceName")) {
        throw "Le fichier CSV doit contenir une colonne nommée 'ServiceName'."
    }

    $windowsServices = Get-CimInstance -ClassName Win32_Service

    $results = foreach ($item in $serviceList) {
        $requestedService = [string]$item.ServiceName

        if ([string]::IsNullOrWhiteSpace($requestedService)) {
            continue
        }

        $service = Get-MatchingService -ServiceName $requestedService -WindowsServices $windowsServices

        if ($service) {
            [PSCustomObject]@{
                RequestedName = $requestedService.Trim()
                ServiceName   = $service.Name
                DisplayName   = $service.DisplayName
                Status        = $service.State
                StartType     = $service.StartMode
            }
        }
        else {
            [PSCustomObject]@{
                RequestedName = $requestedService.Trim()
                ServiceName   = "Non trouvé"
                DisplayName   = "Non trouvé"
                Status        = "NotFound"
                StartType     = "Unknown"
            }
        }
    }

    if (-not $results) {
        throw "Aucun service valide n'a été trouvé dans le fichier CSV."
    }

    $totalCount = ($results | Measure-Object).Count
    $runningCount = ($results | Where-Object { $_.Status -eq "Running" } | Measure-Object).Count
    $stoppedCount = ($results | Where-Object { $_.Status -eq "Stopped" } | Measure-Object).Count
    $notFoundCount = ($results | Where-Object { $_.Status -eq "NotFound" } | Measure-Object).Count
    $disabledCount = ($results | Where-Object { $_.StartType -eq "Disabled" } | Measure-Object).Count

    $generatedDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

    $htmlRows = foreach ($result in $results) {
        $rowClass = switch ($result.Status) {
            "Running"  { "running" }
            "Stopped"  { "stopped" }
            "NotFound" { "not-found" }
            default    { "unknown" }
        }

        @"
            <tr class="$rowClass">
                <td>$(ConvertTo-HtmlText $result.RequestedName)</td>
                <td>$(ConvertTo-HtmlText $result.ServiceName)</td>
                <td>$(ConvertTo-HtmlText $result.DisplayName)</td>
                <td>$(ConvertTo-HtmlText $result.Status)</td>
                <td>$(ConvertTo-HtmlText $result.StartType)</td>
            </tr>
"@
    }

    $htmlReport = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Rapport des services Windows</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f6f8;
            color: #222;
            margin: 0;
            padding: 24px;
        }

        h1 {
            text-align: center;
            margin-bottom: 8px;
        }

        .subtitle {
            text-align: center;
            color: #666;
            margin-bottom: 24px;
        }

        .summary {
            display: flex;
            gap: 12px;
            flex-wrap: wrap;
            justify-content: center;
            margin-bottom: 24px;
        }

        .card {
            background: #fff;
            border: 1px solid #ddd;
            border-radius: 8px;
            padding: 14px 18px;
            min-width: 140px;
            text-align: center;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
        }

        .card span {
            display: block;
            font-size: 24px;
            font-weight: bold;
            margin-top: 4px;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            background: #fff;
            box-shadow: 0 1px 3px rgba(0,0,0,0.08);
        }

        th, td {
            border: 1px solid #ddd;
            padding: 10px;
            text-align: left;
        }

        th {
            background-color: #2f3e46;
            color: #fff;
        }

        tr:nth-child(even) {
            background-color: #f8f9fa;
        }

        tr.running td:nth-child(4) {
            color: #198754;
            font-weight: bold;
        }

        tr.stopped td:nth-child(4) {
            color: #dc3545;
            font-weight: bold;
        }

        tr.not-found td {
            color: #6c757d;
            font-style: italic;
        }

        footer {
            text-align: center;
            color: #666;
            font-size: 12px;
            margin-top: 24px;
        }
    </style>
</head>
<body>
    <h1>Rapport des services Windows</h1>
    <div class="subtitle">Généré le $generatedDate</div>

    <div class="summary">
        <div class="card">Total<span>$totalCount</span></div>
        <div class="card">Démarrés<span>$runningCount</span></div>
        <div class="card">Arrêtés<span>$stoppedCount</span></div>
        <div class="card">Introuvables<span>$notFoundCount</span></div>
        <div class="card">Désactivés<span>$disabledCount</span></div>
    </div>

    <table>
        <thead>
            <tr>
                <th>Service demandé</th>
                <th>Nom technique</th>
                <th>Nom d'affichage</th>
                <th>État</th>
                <th>Type de démarrage</th>
            </tr>
        </thead>
        <tbody>
$htmlRows
        </tbody>
    </table>

    <footer>
        Script créé par BERTRAND Bastien - Exemple de script d'administration PowerShell
    </footer>
</body>
</html>
"@

    $outputDirectory = Split-Path -Path $OutputHtml -Parent

    if ($outputDirectory -and -not (Test-Path -Path $outputDirectory)) {
        New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
    }

    $htmlReport | Set-Content -Path $OutputHtml -Encoding UTF8

    Write-Host "Rapport HTML généré : $OutputHtml" -ForegroundColor Green
    Write-Host ""
    $results | Format-Table -AutoSize

    if ($OpenReport) {
        Start-Process -FilePath $OutputHtml
    }
}
catch {
    Write-Host "Une erreur est survenue pendant la vérification des services." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
