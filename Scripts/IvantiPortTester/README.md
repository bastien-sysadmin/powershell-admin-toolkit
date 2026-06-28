# Ivanti Port Tester

Script PowerShell permettant de tester les ports TCP et UDP utilisés dans un environnement Ivanti / LANDesk.

Ce script remplace une approche basée sur deux scripts séparés en proposant un seul outil avec deux profils de test :

- `Client`
- `CoreServer`

## Fonctionnalités

- Test des ports TCP
- Test des ports UDP
- Profils de ports Client et CoreServer
- Export des résultats en CSV
- Génération d'un rapport HTML
- Ouverture automatique du rapport avec l'option `-OpenReport`

## Structure

```text
IvantiPortTester/
├── Test-IvantiPorts.ps1
├── README.md
└── Reports/
  ├── README.md
  ├── sample-client-port-report.csv
  ├── sample-client-port-report.html
  ├── sample-coreserver-port-report.csv
  └── sample-coreserver-port-report.html
```

## Utilisation

Tester les ports TCP et UDP du profil Client :

```powershell
.\Test-IvantiPorts.ps1 -Target "pc-client-01" -Profile Client -Protocol All
```

Tester uniquement les ports TCP du profil CoreServer :

```powershell
.\Test-IvantiPorts.ps1 -Target "srv-core-01" -Profile CoreServer -Protocol TCP
```

Tester les ports et ouvrir le rapport HTML :

```powershell
.\Test-IvantiPorts.ps1 -Target "srv-core-01" -Profile CoreServer -Protocol All -OpenReport
```

## Paramètres

| Paramètre | Description |
|---|---|
| `Target` | Nom DNS ou adresse IP de la machine à tester |
| `Profile` | Profil de ports à utiliser : `Client` ou `CoreServer` |
| `Protocol` | Protocole à tester : `TCP`, `UDP` ou `All` |
| `OutputDirectory` | Dossier de sortie des rapports |
| `TimeoutMilliseconds` | Timeout appliqué à chaque test de port |
| `OpenReport` | Ouvre automatiquement le rapport HTML |

## Profils de ports

### Profil Client

TCP :

```text
80, 137, 139, 443, 445, 4343, 44345, 5007, 9594, 9595, 9982, 12175, 12176, 16992, 16993, 16994, 33354
```

UDP :

```text
67, 69, 1759, 4011, 9535, 9595, 38293
```

### Profil CoreServer

TCP :

```text
25, 137, 139, 443, 445, 4343, 44343, 44344, 44346, 9535, 9593, 9594, 9595, 9971, 9972, 12174, 16992, 16993, 16994, 33354
```

UDP :

```text
68, 1758, 9535, 9595, 33354, 33355, 38293
```

## Remarque sur les tests UDP

UDP est un protocole sans connexion.  
Un port UDP qui ne répond pas peut être ouvert, filtré par un pare-feu ou simplement ne pas renvoyer de réponse.

Les résultats UDP doivent donc être interprétés avec prudence.

## Exemple de sortie

Le script génère automatiquement un dossier `Reports` contenant :

```text
IvantiPortTest-target-profile-date.csv
IvantiPortTest-target-profile-date.html
```

## Auteur

BERTRAND Bastien
