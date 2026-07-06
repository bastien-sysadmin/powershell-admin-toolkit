# Windows Security Audit

Script PowerShell permettant de réaliser un audit de sécurité de base sur un poste ou serveur Windows.

## Fonctionnalités

Le script contrôle notamment :

- droits administrateur
- état du pare-feu Windows
- état de Microsoft Defender
- UAC
- BitLocker
- SMBv1
- Bureau à distance / NLA
- membres du groupe Administrateurs local
- derniers correctifs installés
- redémarrage en attente
- compte invité local
- Secure Boot
- service WinRM
- politique d'exécution PowerShell

## Structure

```text
WindowsSecurityAudit/
├── Invoke-WindowsSecurityAudit.ps1
├── README.md
└── Reports/
    ├── sample-windows-security-audit.csv
    └── sample-windows-security-audit.html
```

## Utilisation

Lancer l'audit dans la console PowerShell :

```powershell
.\Invoke-WindowsSecurityAudit.ps1
```

Générer un rapport HTML et CSV :

```powershell
.\Invoke-WindowsSecurityAudit.ps1 -ExportHtml -ExportCsv
```

Choisir un dossier de sortie :

```powershell
.\Invoke-WindowsSecurityAudit.ps1 -ExportHtml -ExportCsv -OutputDirectory ".\Reports"
```

## Rapports d'exemple

Le dossier `Reports` contient des rapports fictifs et anonymisés permettant de montrer le type de sortie générée par le script.

Les données d'exemple ne correspondent à aucun poste réel.

## Auteur

BERTRAND Bastien
