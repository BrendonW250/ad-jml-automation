# JML Automation Lab - Active Directory Identity Lifecycle Automation

A hands-on Active Directory lab automating the full **Joiner-Mover-Leaver (JML)** identity lifecycle using PowerShell built to demonstrate the same identity administration and access governance work performed on a daily basis.

## The Problem

Every organization deals with the same core identity management challenge: people join, change roles, and leave and access needs to keep up automatically. Manual account provisioning is slow and error-prone, and manual deprovisioning is a security risk: an account that isn't fully disabled and stripped of access when someone leaves is a real, common attack surface. This project builds and tests automation for all three stages of that lifecycle.

## What I Built

A self-contained Active Directory environment (Windows Server 2025, Server Core) configured as a domain controller (`corplab.local`), with:

- **3 Organizational Units** (Sales, IT, Finance) representing company departments
- **3 matching security groups** (`GRP-Sales-Users`, `GRP-IT-Users`, `GRP-Finance-Users`) representing department-level access
- **3 PowerShell scripts** automating the full identity lifecycle:

| Script | Function |
|---|---|
| `New-Employees.ps1` | **Joiner** — bulk-creates user accounts from a CSV, places each into the correct OU, and adds them to the matching department group |
| `Move-Employee.ps1` | **Mover** — relocates a user to a new department's OU, removes them from their old group, and adds them to the new one |
| `Remove-Employee.ps1` | **Leaver** — disables a departing user's account and strips them from every group except the AD-required default (`Domain Users`) |

## How It Works

**Joiner (`New-Employees.ps1`):** Reads `new-hires.csv` (Name, Department, Title) and loops through each row, using the Department value to dynamically determine both the target OU and target group — no hardcoded per-department logic required.

**Mover (`Move-Employee.ps1`):** Takes a username and a new department as input. Removes all current group memberships (except `Domain Users`, which AD treats as a required primary group and will not allow removing), physically relocates the AD object to the new OU using `Move-ADObject`, then adds the user to the new department's group.

**Leaver (`Remove-Employee.ps1`):** Takes a username as input. Disables the account first before touching any group memberships so that if the script is interrupted partway, the account is already locked rather than left active with incomplete cleanup. Then pulls the user's actual current group memberships and removes them from each one.

All three scripts were manually verified against Active Directory after each run not just trusted based on their own console output using `Get-ADUser`, `Get-ADGroupMember`, and `Get-ADPrincipalGroupMembership`.

## How to Run It

```powershell
# Joiner — bulk-create employees from CSV
.\scripts\New-Employees.ps1

# Mover — relocate an employee to a new department
.\scripts\Move-Employee.ps1 -SamAccountName "jsmith" -NewDepartment "Finance"

# Leaver — disable and revoke access for a departing employee
.\scripts\Remove-Employee.ps1 -SamAccountName "jsmith"
```

Requires a Windows Server domain controller with the AD DS role installed, and the RSAT AD PowerShell module available.

## Challenges & Debugging

Here's what actually went wrong and how it was diagnosed and fixed:

- **Interrupted domain promotion:** An early `Install-ADDSForest` run was interrupted during its automatic restart, leaving AD services (NTDS, DNS) installed but non-functional (`Get-Service` showed them as "Stopped" rather than missing entirely). Diagnosed by directly checking service state via `Get-Service`, then resolved with a clean `Uninstall-WindowsFeature` / reinstall / re-promote cycle rather than attempting to patch a partially broken AD database.
- **PowerShell line continuation corruption:** The original joiner script used backtick (`` ` ``) line continuations, which broke silently after being pasted into Notepad causing commands like `New-ADUser` to be misread as `NewADUser` on some lines. Diagnosed from the exact error text (missing hyphen in the command name) and fixed by rewriting the script with one command per line instead of relying on line-continuation characters.
- **Silent group removal failure:** The mover script's safeguard against removing a user from their required `Domain Users` group referenced `"Domain-Users"` (hyphen) instead of the actual group name `"Domain Users"` (space) a typo that caused the filter to silently fail to exclude it, and combined with PowerShell's default non-terminating error handling, produced a misleading "success" message even when the underlying removal had failed. Fixed the typo and added `-ErrorAction Stop` so a real failure now halts the script and surfaces clearly, instead of printing a false success message.

## Repository Structure

```
ad-jml-automation/
├── README.md
├── scripts/
│   ├── New-Employees.ps1
│   ├── Move-Employee.ps1
│   └── Remove-Employee.ps1
├── sample-data/
│   └── new-hires.csv
└── docs/
    └── screenshots/
```

## Screenshots

See `docs/screenshots/` for:
- AD OU and group structure
- Joiner script results (users created and correctly placed)
- Group membership verification
- Leaver script results (account disabled, groups stripped)
- Mover script results (OU and group membership updated)

---

Built by [BrendonW250] as part of a hands-on IAM engineering skill-building portfolio.

