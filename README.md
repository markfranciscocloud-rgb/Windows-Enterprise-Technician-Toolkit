# Windows Enterprise Technician Toolkit (WETT)

WETT is a PowerShell-first Windows diagnostics, networking, endpoint-security, and incident-triage toolkit built as a hands-on IT and cybersecurity portfolio project.

> **Current release:** `v0.1.0` — read-only diagnostics and reporting.

## Why this project exists

Many PC “optimization” scripts immediately delete files, reset networking, or change system settings. WETT follows a safer enterprise troubleshooting sequence:

1. Identify the system.
2. Collect evidence.
3. Reproduce and isolate the issue.
4. Document findings.
5. Repair only with authorization, backups, and rollback planning.

## Phase 1 features

- System and hardware snapshot using CIM instead of deprecated WMIC workflows
- Network adapter, addressing, DNS, gateway, and route visibility
- Connectivity and DNS testing
- TCP connection-to-process mapping
- Microsoft Defender, firewall, BitLocker, TPM, Secure Boot, and local-admin audit
- Timestamped HTML and JSON triage reports
- SHA-256 report integrity manifest
- Action logging
- Built-in learning cards
- GitHub Actions workflow for PSScriptAnalyzer and Pester

## Safety model

Version 0.1.0 is intentionally **read-only by default**. It does not:

- Delete temporary files
- Reset Winsock or TCP/IP
- Clear Windows Update caches
- Disable security controls
- Kill user processes
- Change firewall or registry settings

Repair actions will be added later in a separate, clearly labeled module with confirmation, administrator checks, logging, and rollback guidance.

## Requirements

- Windows 10/11 or Windows Server
- Windows PowerShell 5.1 or PowerShell 7+
- Some security fields may require an elevated PowerShell session

## Quick start

### Option A: launcher

Double-click `Start-WETT.bat`.

### Option B: PowerShell

```powershell
Set-Location 'C:\Path\To\Windows-Enterprise-Technician-Toolkit'
Unblock-File .\WETT.ps1
.\WETT.ps1
```

Run PowerShell as Administrator only when you need access to protected security details. Routine diagnostics should use normal privileges when possible.

## Repository structure

```text
Windows-Enterprise-Technician-Toolkit/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
├── Config/
├── Docs/
├── Logs/
├── Modules/
├── Reports/
├── Tests/
├── WETT.ps1
├── Start-WETT.bat
├── README.md
├── ROADMAP.md
├── SECURITY.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── LICENSE
├── .editorconfig
└── .gitignore
```

## First Git commands

```powershell
git init
git branch -M main
git add .
git commit -m "feat: create WETT v0.1.0 diagnostic foundation"
```

After creating an empty GitHub repository:

```powershell
git remote add origin https://github.com/YOUR-USERNAME/Windows-Enterprise-Technician-Toolkit.git
git push -u origin main
```

## Portfolio talking points

- Replaced legacy WMIC-style collection with structured PowerShell/CIM objects.
- Separated evidence collection from remediation to reduce operational risk.
- Added repeatable JSON/HTML reporting and SHA-256 integrity verification.
- Designed modules around common help-desk, endpoint, networking, and SOC workflows.
- Added automated linting and tests through GitHub Actions.

## Standards and technical references

- Microsoft PowerShell documentation: https://learn.microsoft.com/powershell/
- Microsoft Windows security baselines: https://learn.microsoft.com/windows/security/operating-system-security/device-management/windows-security-configuration-framework/windows-security-baselines
- NIST Cybersecurity Framework 2.0: https://www.nist.gov/cyberframework
- NIST SP 800-61 Rev. 3: https://csrc.nist.gov/pubs/sp/800/61/r3/final
- GitHub PowerShell CI guidance: https://docs.github.com/actions/automating-builds-and-tests/building-and-testing-powershell

## Authorized use

Use WETT only on systems you own or are explicitly authorized to administer. The project is intended for legitimate diagnostics, education, security operations, and incident response.
