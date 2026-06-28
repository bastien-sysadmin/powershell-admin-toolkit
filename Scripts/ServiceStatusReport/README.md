# Service Status Report

Script PowerShell permettant de vérifier l'état de services Windows à partir d'un fichier CSV et de générer un rapport HTML.

Ce projet peut être utilisé pour contrôler rapidement une liste de services attendus sur un poste ou un serveur Windows, par exemple dans un contexte d'administration système, de supervision ponctuelle ou de contrôle après maintenance.

## Fonctionnalités

- Lecture d'une liste de services depuis un fichier CSV
- Vérification de l'existence des services
- Récupération de l'état du service : `Running`, `Stopped` ou `NotFound`
- Récupération du type de démarrage : `Auto`, `Manual`, `Disabled` ou `Unknown`
- Génération d'un rapport HTML avec résumé global
- Possibilité d'ouvrir automatiquement le rapport généré

## Structure

```text
ServiceStatusReport/
├── Get-ServiceStatusReport.ps1
├── sample-services.csv
└── README.md
```

## Prérequis

- Windows 10 / Windows 11 / Windows Server
- PowerShell 5.1 ou PowerShell 7+
- Droits suffisants pour interroger les services Windows

## Format du fichier CSV

Le fichier CSV doit contenir une colonne nommée `ServiceName`.

Exemple :

```csv
ServiceName
wuauserv
bits
spooler
```

Le fichier `sample-services.csv` regroupe des exemples génériques de services Windows ainsi que des exemples de services Ivanti / LANDesk anonymisés.

Le script accepte un nom technique de service ou un nom d'affichage.

## Utilisation

Exécution avec le fichier d'exemple par défaut :

```powershell
.\Get-ServiceStatusReport.ps1
```

Exécution avec un fichier CSV personnalisé :

```powershell
.\Get-ServiceStatusReport.ps1 -ServiceListCsv ".\sample-services.csv"
```

Exécution avec un nom de rapport personnalisé :

```powershell
.\Get-ServiceStatusReport.ps1 -ServiceListCsv ".\sample-services.csv" -OutputHtml ".\Report-ServiceStatus.html"
```

Exécution avec ouverture automatique du rapport :

```powershell
.\Get-ServiceStatusReport.ps1 -OpenReport
```

## Fichier d'exemple

- `sample-services.csv` : liste d'exemple contenant des services Windows génériques ainsi que des services Ivanti / LANDesk anonymisés.

Les données fournies sont des exemples et ne contiennent aucune donnée liée à un environnement réel d'entreprise.

## Sécurité

Avant toute publication publique, il est recommandé de vérifier que les fichiers CSV ne contiennent pas :

- noms de serveurs internes ;
- domaines Active Directory ;
- chemins réseau ;
- comptes utilisateurs ;
- informations propres à une entreprise ou un client.

## Auteur

BERTRAND Bastien
