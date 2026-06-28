<#
.SYNOPSIS
    Vérifie des chemins UNC, HTTP et HTTPS puis génère un rapport HTML

.DESCRIPTION
    Ce script lit un fichier CSV contenant une liste de packages et de chemins de déploiement.

    Pour chaque entrée, il permet de :
    - identifier le type de chemin utilisé : UNC, HTTP ou HTTPS
    - tester l'accessibilité du chemin
    - détecter les chemins en doublon ;
    - générer un rapport HTML interactif avec recherche, filtres et résumé

    Le rapport généré permet de visualiser rapidement les chemins valides, les chemins en échec
    ainsi que les doublons présents dans la liste analysée.

.EXAMPLE
    .\Check-DeploymentPaths.ps1

    Lance l'analyse à partir du fichier CSV présent dans le même dossier que le script
    et génère automatiquement le rapport HTML.

.INPUTS
    Fichier CSV contenant les noms des packages et les chemins à vérifier.

.OUTPUTS
    Rapport HTML contenant les résultats des tests, les doublons détectés et un résumé global.

.NOTES
    Auteur : BERTRAND Bastien
    Usage  : Exemple de script d'administration PowerShell
    Projet : Audit de chemins de déploiement et génération de rapport HTML

    Les données utilisées dans les exemples publics doivent être anonymisées avant publication.
#>


# Obtenir le répertoire du script en cours
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Chemin du fichier CSV contenant les chemins et noms à tester
$cheminFichier = Join-Path $scriptDir "liste.csv"
$chemins = Import-Csv -Path $cheminFichier

# Chemin du fichier HTML de sortie
$cheminFichierHTML = Join-Path $scriptDir "Report_check_Combined.html"

# Créer des tableaux pour les chemins déjà rencontrés et les doublons
$cheminsVus = @()
$doublons = @()
$resultats = @()
$nombreEchecs = 0
$nombreDoublons = 0

# Fonction pour tester un chemin UNC
function TestUNCPath($cheminUNC) {
    Write-Host "Test UNC: $cheminUNC"
    if (Test-Path $cheminUNC) {
        return "success"
    } else {
        return "failure"
    }
}

# Fonction pour tester une URL HTTP
function TestHTTPPath($url) {
    Write-Host "Test HTTP: $url"
    try {
        $request = [System.Net.HttpWebRequest]::Create($url)
        $request.Timeout = 1000000  # Timeout de 1000 secondes
        if ($url.StartsWith("https://")) {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        }
        $response = $request.GetResponse()
        $status = $response.StatusCode
        $response.Close()
        if ($status -eq [System.Net.HttpStatusCode]::OK) {
            return "success"
        } else {
            return "failure"
        }
    } catch {
        return "failure"
    }
}

# Générer le contenu HTML
$htmlContent = @"
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; background-color: #f4f4f4; color: #333; margin: 0; padding: 0; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; background-color: #fff; box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1); }
        th, td { border: 1px solid #ddd; padding: 10px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        tr:hover { background-color: #e8e8e8; cursor: pointer; transition: background-color 0.3s ease; }
        .doublon { color: red; font-weight: bold; background-color: #ffcccc; }
        .success { color: green; font-weight: bold; background-color: #d4edda; }
        .failure { color: red; font-weight: bold; background-color: #f8d7da; }
        input[type="text"] { padding: 8px; margin: 20px 0; width: 100%; max-width: 300px; display: block; border: 1px solid #ccc; border-radius: 4px; }
        select { padding: 8px; margin: 20px 0; border: 1px solid #ccc; border-radius: 4px; }
        h1 { font-size: 2em; text-align: center; color: #333; margin-top: 20px; }
        footer { text-align: center; font-size: 12px; color: #777; margin-top: 30px; }
        .summary { 
            font-size: 14px; 
            font-weight: bold; 
            color: #333; 
            margin: 20px 0; 
            padding: 15px; 
            background-color: #e9f7ec; 
            border: 1px solid #c8e6c9; 
            border-radius: 8px; 
            display: flex; 
            justify-content: space-between; 
            box-sizing: border-box;
            width: 100%;
            max-width: 600px;
            margin-left: auto;
            margin-right: auto;
        }
        .summary span { 
            padding-left: 10px; 
        }
    </style>
</head>
<body>
   <h1>Rapport des Tests de Chemins et Doublons</h1>
   
   <!-- Zone de recherche (en haut) -->
   <input type="text" id="searchInput" onkeyup="searchTable()" placeholder="Rechercher...">
   
   <!-- Menu avec les filtres -->
   <label for="filterSelect">Filtrer par :</label>
   <select id="filterSelect" onchange="filterTable()">
       <option value="all">Tout afficher</option>
       <option value="doublon">Doublons</option>
       <option value="success">Succès</option>
       <option value="failure">Échec</option>
       <option value="no-doublon">Sans doublon</option>
       <option value="failure-or-doublon">Échec ou Doublon</option>
       <option value="http">Chemins HTTP</option>
       <option value="https">Chemins HTTPS</option>
       <option value="unc">Chemins UNC</option>
   </select>
   
   <!-- Zone de résumé (en dessous du filtre) -->
   <div class="summary">
       <div>Nombre d'échecs : <span id="nombreEchecs">0</span></div>
       <div>Nombre de doublons : <span id="nombreDoublons">0</span></div>
   </div>

   <!-- Tableau des résultats -->
   <table>
       <thead>
           <tr><th>Nom Paquet</th><th>Chemin</th><th>Résultat Test</th><th>Doublon</th><th>Type de Chemin</th></tr>
       </thead>
       <tbody id="tableBody">
"@

# Parcourir chaque ligne du fichier CSV
foreach ($ligne in $chemins) {
    $nomPaquet = $ligne.Nom
    $chemin = $ligne.Chemin

    # Tester le chemin (UNC ou HTTP)
    $testResult = "failure"  # Valeur par défaut
    $cheminType = ""

    if ($chemin.StartsWith("http://")) {
        $testResult = TestHTTPPath $chemin
        $cheminType = "HTTP"
    } elseif ($chemin.StartsWith("https://")) {
        $testResult = TestHTTPPath $chemin
        $cheminType = "HTTPS"
    } elseif ($chemin.StartsWith("\\")) {
        $testResult = TestUNCPath $chemin
        $cheminType = "UNC"
    }

    # Vérifier les doublons
    $doublonText = "Non"
    if ($cheminsVus -contains $chemin) {
        $doublonText = "Oui"
        $nombreDoublons++
    } else {
        $cheminsVus += $chemin
    }

    # Compter les échecs
    if ($testResult -eq "failure") {
        $nombreEchecs++
    }

    # Ajouter la ligne HTML pour ce chemin
    $testClass = if ($testResult -eq "success") { "success" } else { "failure" }
    $doublonClass = if ($doublonText -eq "Oui") { "doublon" } else { "" }

    $htmlContent += "<tr class='no-filter'>
                        <td>$nomPaquet</td>
                        <td>$chemin</td>
                        <td class='$testClass'>$testResult</td>
                        <td class='$doublonClass'>$doublonText</td>
                        <td>$cheminType</td>
                    </tr>"
}

$htmlContent += @"
   </tbody>
   </table>

   <script>
       // Mettre à jour le nombre d'échecs et de doublons dans le résumé
       document.getElementById('nombreEchecs').textContent = '$nombreEchecs';
       document.getElementById('nombreDoublons').textContent = '$nombreDoublons';

       function searchTable() {
           var input = document.getElementById('searchInput');
           var filter = input.value.toUpperCase();
           var table = document.getElementById('tableBody');
           var tr = table.getElementsByTagName('tr');
           for (var i = 0; i < tr.length; i++) {
               var td1 = tr[i].getElementsByTagName('td')[0];
               var td2 = tr[i].getElementsByTagName('td')[1];
               if (td1 && td2) {
                   var txtValue1 = td1.textContent || td1.innerText;
                   var txtValue2 = td2.textContent || td2.innerText;
                   if (txtValue1.toUpperCase().indexOf(filter) > -1 || txtValue2.toUpperCase().indexOf(filter) > -1) {
                       tr[i].style.display = '';
                   } else {
                       tr[i].style.display = 'none';
                   }
               }
           }
       }

       function filterTable() {
           var select = document.getElementById('filterSelect');
           var filter = select.value;
           var rows = document.querySelectorAll('#tableBody tr');
           rows.forEach(function(row) {
               var showRow = false;

               if (filter === 'all') {
                   showRow = true;
               } else if (filter === 'doublon' && row.querySelector('td:nth-child(4)').textContent.trim() === 'Oui') {
                   showRow = true;
               } else if (filter === 'success' && row.querySelector('td:nth-child(3)').textContent.trim() === 'success') {
                   showRow = true;
               } else if (filter === 'failure' && row.querySelector('td:nth-child(3)').textContent.trim() === 'failure') {
                   showRow = true;
               } else if (filter === 'no-doublon' && row.querySelector('td:nth-child(4)').textContent.trim() === 'Non') {
                   showRow = true;
               } else if (filter === 'failure-or-doublon' && (row.querySelector('td:nth-child(3)').textContent.trim() === 'failure' || row.querySelector('td:nth-child(4)').textContent.trim() === 'Oui')) {
                   showRow = true;
               } else if (filter === 'http' && row.querySelector('td:nth-child(5)').textContent.trim() === 'HTTP') {
                   showRow = true;
               } else if (filter === 'https' && row.querySelector('td:nth-child(5)').textContent.trim() === 'HTTPS') {
                   showRow = true;
               } else if (filter === 'unc' && row.querySelector('td:nth-child(5)').textContent.trim() === 'UNC') {
                   showRow = true;
               }

               row.style.display = showRow ? '' : 'none'; 
           });
       }
   </script>

   <footer>
       Généré le $(Get-Date -Format 'dd/MM/yyyy')<br>
       Script créé par Bastien Bertrand
   </footer>
</body>
</html>
"@

# Sauvegarder le fichier HTML
$htmlContent | Out-File -FilePath $cheminFichierHTML -Force

# Ouvrir le fichier HTML dans le navigateur par défaut
Start-Process $cheminFichierHTML
