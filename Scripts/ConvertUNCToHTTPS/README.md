# Convert UNC To HTTPS

Script PowerShell permettant de convertir des chemins UNC en chemins HTTPS dans un fichier texte, XML ou export de packages.

## Objectif

Ce script peut être utilisé dans un contexte d'administration système ou de migration de sources de déploiement, par exemple lorsqu'un environnement passe de chemins réseau UNC vers des URLs HTTPS.

## Fonctionnalités

- Lecture d'un fichier source contenant des chemins UNC
- Conversion des chemins UNC au format HTTPS
- Génération d'un fichier de sortie modifié
- Génération d'un fichier de log des changements
- Paramètres personnalisables pour le fichier source, le fichier de sortie et le fichier de log

## Structure

```text
ConvertUNCToHTTPS/
├── Convert-UNCToHTTPS.ps1
├── sample-package-export.ldms
└── README.md
```

## Utilisation

Depuis PowerShell, dans le dossier du script :

```powershell
.\Convert-UNCToHTTPS.ps1
```

Avec des chemins personnalisés :

```powershell
.\Convert-UNCToHTTPS.ps1 -InputFile ".\sample-package-export.ldms" -OutputFile ".\converted-package-export.ldms" -LogFile ".\change-log.txt"
```

## Exemple de conversion

Avant :

```text
\\SRV-FILES-01\Packages$\7-Zip\install-7zip.ps1
```

Après :

```text
https://SRV-FILES-01/Packages$/7-Zip/install-7zip.ps1
```

## Données d'exemple

Le fichier `sample-package-export.ldms` contient uniquement des données fictives et anonymisées.
Il ne correspond à aucun environnement réel d'entreprise.

## Sécurité

Avant toute publication publique, vérifier qu'aucun fichier ne contient :

- nom de serveur réel ;
- domaine interne ;
- compte utilisateur ;
- chemin réseau réel ;
- URL interne ;
- information liée à un client ou à un ancien employeur.

## Auteur

BERTRAND Bastien
