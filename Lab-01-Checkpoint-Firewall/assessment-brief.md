# Instructor Brief — Check Point Firewall: Administration & Policy Management (Lab 01)

**Domain / Level:** Network Security — Check Point (Windows jump host / PowerShell + Management API) · **Intermediate / Advanced** · **Hosting tier A** (native CloudLabs Windows JumpVM with SmartConsole, plus a Check Point CloudGuard Security Management server and Security Gateway).
**Target time:** ~120 min work · **150 min** provisioned.
**Cloud field:** `azure` · **Level field:** `Advanced`.

## Scenario

The candidate is a firewall administrator operating a Check Point CloudGuard environment. From a Windows jump VM with **SmartConsole**, they build and manage the security policy in six steps: create and publish a host object, add an access rule, introduce a policy layer with Application Control, configure SSH logging/alerting, analyze events with SmartLog/SmartEvent, and produce a Compliance report. All work targets the lab's own Check Point Security Management server (`10.0.0.10`); validators run on the jump VM and call the Management REST API to inspect the **published** configuration.

## Environment (staged by `DeploymentPackage/deploy-01.json` + `bootstrap-01.ps1`)

- A **Windows Server 2022 jump VM** (`labvm-<DeploymentID>`) with **Check Point SmartConsole**, on the management subnet (10.0.0.0/24) so it can reach the Management API at `10.0.0.10`.
- A Check Point **CloudGuard Security Management** server (`cp-mgmt`, 10.0.0.10, Management API on 443) and a Check Point **Security Gateway** (`cp-gw`, 10.0.0.20) with mgmt/external/internal NICs. Admin: `admin` / `Chkp@12345`. Both receive **unattended Gaia first-time configuration** via `osProfile.customData` (`config_system`): the management primary with GUI clients = any, and the gateway with the one-time SIC key `vpn123456`.
- The jump VM CSE runs **`bootstrap-01.ps1`**, which **installs SmartConsole** (+ Desktop/Start Menu shortcuts), waits for the Management API, then over the REST API **adds the gateway object, establishes SIC** with the one-time key, **publishes**, and **installs the baseline `Standard` policy** on `cp-gw` — leaving the environment learner-ready. It also writes **`C:\LabFiles\README.txt`**. Only the baseline (gateway onboarding + default package) is seeded; none of the six assessed deliverables are pre-created. **Licensing** is a marketplace prerequisite (see caveats).

## Answer key

All work is performed from the jump VM in SmartConsole, or via the Management API (`mgmt_cli` / `web_api`). Log in with `mgmt_cli login user admin password Chkp@12345 > sid.txt` and reuse the session; **publish** after each change.

- **T1 — SmartConsole Operation (publish host `WebServer-01`):**
  ```
  mgmt_cli -s sid.txt add host name "WebServer-01" ip-address "10.0.2.50"
  mgmt_cli -s sid.txt publish
  ```
  *(SmartConsole: Objects → New → Host → name `WebServer-01`, IPv4 `10.0.2.50` → Publish.)*

- **T2 — Security Rulebase Management (rule `Allow-Web`):**
  ```
  mgmt_cli -s sid.txt add access-rule layer "Network" position bottom name "Allow-Web" \
      destination "WebServer-01" service "http" service.1 "https" action "Accept"
  mgmt_cli -s sid.txt publish
  ```

- **T3 — Policy Layering & Application Control (`App-Control` layer):**
  ```
  mgmt_cli -s sid.txt add access-layer name "App-Control" applications-and-url-filtering "true"
  mgmt_cli -s sid.txt publish
  ```
  *(Or add an inline/ordered layer in the Standard package with the Applications & URL Filtering blade enabled.)*

- **T4 — SSH Access Logging & Alerting (Track = Log/Alert):**
  ```
  mgmt_cli -s sid.txt add access-rule layer "Network" position bottom name "SSH-Admin" \
      service "ssh" action "Accept" track "Log"
  mgmt_cli -s sid.txt publish
  ```
  *(Or set Track = Log/Alert on the existing rule that matches the `ssh` service.)*

- **T5 — Event Analysis (SmartLog/SmartEvent):** ensure ≥1 rule has Track = Log/Alert (T4 satisfies this), generate/observe traffic, then open **Logs & Monitor → SmartLog** and the **SmartEvent** views to analyze the events. *(GUI — inspection-verified.)*

- **T6 — Compliance Reporting:** open the **Compliance** blade (Logs & Monitor → Compliance), run an assessment, and review the score/findings; confirm a published policy package exists (`mgmt_cli -s sid.txt show packages`). *(GUI report — inspection-verified.)*

(Full SmartConsole GUI steps and `mgmt_cli` equivalents are in `LabGuidePackage/Solution-Guide/solution-guide.md`.)

## Scoring rubric (100 pts)

| Item | Pts | Pass criteria (validator) |
|---|---|---|
| T1 host `WebServer-01` created & published | 20 | validate-task1-smartconsole.ps1 → Succeeded |
| T2 access rule `Allow-Web` published | 20 | validate-task2-rulebase.ps1 → Succeeded |
| T3 access layer with Application & URL Filtering | 20 | validate-task3-policy-layering.ps1 → Succeeded |
| T4 SSH rule Track = Log/Alert | 20 | validate-task4-ssh-logging.ps1 → Succeeded |
| T5 logging active for SmartLog/SmartEvent (partly inspection-based) | 10 | validate-task5-event-analysis.ps1 → Succeeded |
| T6 Compliance in use / policy package (partly inspection-based) | 10 | validate-task6-compliance.ps1 → Succeeded |

Pass ≥ **60** (at least the three core policy tasks fully complete). Advanced sign-off = 100 with **all six** tasks passing. T5/T6 carry fewer points because they are partly GUI/inspection-verified.

## Notes / caveats

- **Check Point CloudGuard requires a license.** The deployment uses **PAYG**: the ARM variables `cpImageOffer` / `cpMgmtImageSku` / `cpGwImageSku` default to `check-point-cg-r82` / `mgmt-payg` / `sg-payg`. Confirm the exact offer/sku for the region with `az vm image list --publisher checkpoint --all`, accept terms with `az vm image terms accept`, and adjust the variables before deploying.
- The **full Management + Gateway bring-up is automated inside this package**: `config_system` (customData) completes the Gaia first-time configuration on both Check Point VMs, and `bootstrap-01.ps1` installs SmartConsole, establishes SIC, and installs the baseline policy. SIC/policy steps retry with generous timeouts because the Check Point VMs reboot during first-time config; if onboarding has not finished when a candidate first opens SmartConsole, the README documents a one-screen manual add-gateway fallback. The **`config_system` parameter names are version-sensitive** (validated against R81.x/R82) and the **SmartConsole installer URL** (`$SmartConsoleUrl` in the bootstrap) should point at the matching R82 build — confirm both against the chosen image.
- **Validators run on the jump VM** and call the Management API (`https://10.0.0.10/web_api`). They require the Management API enabled for the jump host and the admin credentials. They are read-only (login → show… → logout) and safe to re-run; HTTP is always `OK`, pass/fail is in the JSON `Status`.
- **s1 / s5 / s6 are partly GUI/inspection-verified.** SmartConsole operation is confirmed via the object it publishes; SmartLog/SmartEvent and the Compliance blade report are GUI tools — the validators check the closest API proxy (tracked rules / a published package). Confirm the report/analysis by observation.
- Object/rulebase/layer **markers may need tuning** to the live environment (default package name `Standard`, default access layer name `Network`, service names `http`/`https`/`ssh`).
- Knowledge-check questions are **excluded** from this package.
