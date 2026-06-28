# PowerShell Admin Toolkit

Collection de scripts PowerShell destinés à faciliter l'administration Windows, le diagnostic système, le reporting et l'automatisation de tâches IT courantes.

Ce dépôt regroupe des scripts simples et des outils plus avancés créés dans un contexte d'administration systèmes, postes de travail et environnements de déploiement.

## Objectif

Ce dépôt me permet de centraliser différents scripts PowerShell utiles pour l'administration Windows, le diagnostic, le contrôle de services, l'audit de chemins de déploiement et la génération de rapports.

Les scripts publiés ici sont pensés pour être :

- lisibles
- documentés
- facilement adaptables
- réutilisables dans différents environnements Windows
- accompagnés d'exemples anonymisés lorsque nécessaire

## Scripts disponibles

| Script | Description |
|---|---|
| `Scripts/Get-SystemReport.ps1` | Génère un rapport système de base : nom du poste, utilisateur, version Windows, processeur, mémoire RAM, uptime et espace disque. |
| `Scripts/Check-DiskSpace.ps1` | Vérifie l'espace disque disponible sur les disques locaux et affiche une alerte si un disque passe sous le seuil défini. |
| `Scripts/Get-InstalledSoftware.ps1` | Liste les logiciels installés depuis le registre Windows, avec possibilité de filtrer par nom et d'exporter le résultat en CSV. |
| `Scripts/DeploymentPathAudit/Check-DeploymentPaths.ps1` | Vérifie des chemins UNC, HTTP et HTTPS, détecte les doublons et génère un rapport HTML interactif. |
| `Scripts/ConvertUNCToHTTPS/Convert-UNCToHTTPS.ps1` | Convertit des chemins UNC en chemins HTTPS dans un fichier texte ou un export de packages, avec génération d'un fichier de sortie et d'un log. |
| `Scripts/ServiceStatusReport/Get-ServiceStatusReport.ps1` | Vérifie l'état de services Windows à partir d'un fichier CSV et génère un rapport HTML avec résumé global. |
| `Scripts/IvantiPortTester/Test-IvantiPorts.ps1` | Teste les ports TCP/UDP utilisés dans un environnement Ivanti / LANDesk et génère des rapports CSV/HTML. |

## Structure du dépôt

```text
powershell-admin-toolkit/
│
├── README.md
│
└── Scripts/
    ├── Get-SystemReport.ps1
    ├── Check-DiskSpace.ps1
    ├── Get-InstalledSoftware.ps1
    │
    ├── DeploymentPathAudit/
    │   ├── README.md
    │   ├── Check-DeploymentPaths.ps1
    │   ├── sample-list.csv
    │   └── sample-report.html
    │
    ├── ConvertUNCToHTTPS/
    │   ├── README.md
    │   ├── Convert-UNCToHTTPS.ps1
    │   ├── sample-package-export.ldms
    │   ├── sample-converted-package-export.ldms
    │   └── sample-change-log.txt
    │
    ├── ServiceStatusReport/
    │   ├── README.md
    │   ├── Get-ServiceStatusReport.ps1
    │   └── sample-services.csv
    │
    └── IvantiPortTester/
        ├── README.md
        ├── Test-IvantiPorts.ps1
        └── Reports/
            ├── README.md
            ├── sample-client-port-report.csv
            ├── sample-client-port-report.html
            ├── sample-coreserver-port-report.csv
            └── sample-coreserver-port-report.html
```

## Compétences mises en avant

- PowerShell
- Administration Windows
- Diagnostic système
- Automatisation IT
- Inventaire logiciel
- Contrôle de services Windows
- Tests réseau TCP/UDP
- Reporting HTML / CSV
- Audit de chemins UNC, HTTP et HTTPS
- Bonnes pratiques de scripting
- Documentation technique

## Prérequis

- Windows 10 / Windows 11 / Windows Server
- PowerShell 5.1 ou PowerShell 7+
- Droits administrateur selon les scripts utilisés
- Exécution locale des scripts PowerShell

## Exemples d'utilisation

### Générer un rapport système

```powershell
.\Scripts\Get-SystemReport.ps1
```

### Vérifier l'espace disque

```powershell
.\Scripts\Check-DiskSpace.ps1
```

Avec un seuil personnalisé :

```powershell
.\Scripts\Check-DiskSpace.ps1 -ThresholdPercent 20
```

### Lister les logiciels installés

```powershell
.\Scripts\Get-InstalledSoftware.ps1
```

Exporter le résultat en CSV :

```powershell
.\Scripts\Get-InstalledSoftware.ps1 -ExportCsv
```

### Vérifier des chemins de déploiement

```powershell
.\Scripts\DeploymentPathAudit\Check-DeploymentPaths.ps1
```

### Convertir des chemins UNC en HTTPS

```powershell
.\Scripts\ConvertUNCToHTTPS\Convert-UNCToHTTPS.ps1
```

### Générer un rapport d'état des services

```powershell
.\Scripts\ServiceStatusReport\Get-ServiceStatusReport.ps1
```

### Tester les ports Ivanti / LANDesk

```powershell
.\Scripts\IvantiPortTester\Test-IvantiPorts.ps1 -Target "srv-core-01.example.local" -Profile CoreServer -Protocol All
```

## Données d'exemple

Certains dossiers contiennent des fichiers d'exemple tels que des CSV, rapports HTML ou exports fictifs.

Ces fichiers sont volontairement anonymisés et ne correspondent à aucun environnement réel d'entreprise.

Ils sont fournis uniquement pour montrer :

- le format attendu en entrée ;
- le type de résultat généré ;
- la structure des rapports produits par les scripts.

## Sécurité et confidentialité

Aucune information confidentielle ne doit être publiée dans ce dépôt.

Avant toute publication, les éléments suivants doivent être supprimés ou remplacés par des valeurs fictives :

- noms de serveurs réels ;
- domaines internes ;
- adresses IP internes ;
- chemins réseau réels ;
- noms d'entreprise ou de client ;
- mots de passe ;
- tokens ;
- clés API ;
- données issues d'un environnement professionnel réel.

Les fichiers d'exemple présents dans ce dépôt utilisent des valeurs fictives comme :

```text
srv-core-01.example.local
pc-client-01.example.local
\\SRV-FILES-01\Deploy\Software
https://deploy.example.local/packages
```

## Notes

Ces scripts sont fournis à titre d'exemple et doivent être testés dans un environnement adapté avant toute utilisation en production.

## Auteur

BERTRAND Bastien
