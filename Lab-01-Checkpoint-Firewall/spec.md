This Package Includes

Deliverables Included in the Package

• Lab Guide
• Master Document
• Inline Validations
• ARM Deployment + Custom Script Extension
• Solution Guide (facilitator-only)
• Instructor Brief (facilitator-only)

Inline Validations

Pre-configured inline validations enabled (6 task validations). These validators run **on the Windows jump VM** (`Invoke-AzVMRunCommand` → `RunPowerShellScript`) and call the **Check Point Management REST API** at `https://10.0.0.10/web_api` to inspect the candidate's **published** policy (objects, rulebase, access layers, policy packages). Each task maps to a validation script keyed by a validation-step UUID; see Validations/Validation.md.

Inline Assessment Questions

Not included in this package (knowledge-check questions are out of scope for this assessment).

Lab Environment Setup & Deployment

Lab provisioning and setup include one or more of the following components:

• ARM template deployment (CloudLabs Windows JumpVM — Windows Server 2022 Datacenter Azure Edition, Standard_B2s — with Check Point SmartConsole)
• Check Point **CloudGuard Security Management** server (`cp-mgmt`, 10.0.0.10, Management API on 443) and a Check Point **Security Gateway** (`cp-gw`), publisher `checkpoint`, multi-vCPU `Standard_D3_v2`
• Custom Script Extension (CSE / PowerShell) — runs `bootstrap-01.ps1`: installs SmartConsole (+ shortcuts), waits for the Management API, onboards `cp-gw` over the REST API (SIC via one-time key), publishes, installs the baseline `Standard` policy, and writes a task README. The Check Point VMs self-configure via unattended `config_system` (customData)
• Supporting deployment configurations as required

Assessment Profile

• Domain: Network Security — Check Point (Windows jump host / PowerShell + Management API)
• Level: Intermediate / Advanced
• Target duration: 150 minutes (150 minutes provisioned)
• Hosting tier: A (native — Azure Windows VM + Check Point CloudGuard Management + Gateway)

Scenario & Validation Summary

• Exercise 1 / Task 1 — SmartConsole Operation: create & publish host `WebServer-01` → validate-task1-smartconsole.ps1
• Exercise 2 / Task 1 — Security Rulebase Management: access rule `Allow-Web` → validate-task2-rulebase.ps1
• Exercise 3 / Task 1 — Policy Layering & Application Control: access layer with Application & URL Filtering → validate-task3-policy-layering.ps1
• Exercise 4 / Task 1 — SSH Access Logging & Alerting: SSH rule Track = Log/Alert → validate-task4-ssh-logging.ps1
• Exercise 5 / Task 1 — Event Analysis (SmartLog/SmartEvent): logging active → validate-task5-event-analysis.ps1
• Exercise 6 / Task 1 — Compliance Reporting: Compliance in use / published policy package → validate-task6-compliance.ps1

Note

• **Check Point CloudGuard requires a license.** This package uses the **PAYG** plan — the ARM variables `cpImageOffer` / `cpMgmtImageSku` / `cpGwImageSku` default to `check-point-cg-r82` / `mgmt-payg` / `sg-payg`. The **exact offer/sku must be confirmed** for the target region with `az vm image list --publisher checkpoint --all`, the marketplace terms accepted with `az vm image terms accept`, and the variables adjusted to match before deployment.
• The **full Management + Gateway bring-up is automated within this package** — unattended Gaia first-time configuration via `config_system` (customData) on both Check Point VMs, plus SmartConsole install, SIC establishment, and baseline `Standard` policy install driven by `bootstrap-01.ps1`. (CloudGuard **licensing** remains a marketplace prerequisite: accept terms + confirm offer/sku per region.)
• Scenarios **s1 / s5 / s6** (SmartConsole operation, SmartLog/SmartEvent analysis, Compliance blade report) are **GUI / observational and partly inspection-verified**; their validators query the Management API for the closest verifiable proxy.
• Validators query the **Management API**; object/rulebase/layer **markers may need tuning** to the live Check Point environment (management IP, credentials, package/layer names).

Exclusions

This package does not include:

• Scoring or grading mechanisms beyond pass/fail inline validations
• Inline assessment questions
