# CloudLabs by Spektra Systems | Facilitator Solution Guide (NOT for candidates)

## Check Point Firewall — Administration & Policy Management (Lab 01): Answer Key + Walkthrough

This document mirrors the candidate exercise order. Each task lists the recommended approach with the exact **SmartConsole** GUI steps and the equivalent **`mgmt_cli`** / Management API commands, the expected result, and the validation expectation. All work is performed from the Windows jump VM against the lab's own Check Point Security Management server at `10.0.0.10` (admin / `Chkp@12345`).

> **Setup (once):** RDP into the jump VM and open **SmartConsole**, connecting to `10.0.0.10` with `admin` / `Chkp@12345`. For the CLI path, open PowerShell and obtain a Management API session you reuse across commands:
> ```powershell
> # establish a session (the validators use the web_api directly; mgmt_cli works too)
> mgmt_cli login user admin password Chkp@12345 --unsafe true > sid.txt
> # ... run add/set commands with -s sid.txt ...
> mgmt_cli publish -s sid.txt
> ```
> Default policy package is **`Standard`**, default access layer is **`Network`**. **Publish** (and install policy where relevant) after each task — the validators read the **published** database via `https://10.0.0.10/web_api`.

---

## Exercise 1 / Task 1 — SmartConsole Operation: create & publish host `WebServer-01`

**Objective:** A published host object named `WebServer-01` (10.0.2.50) exists.

**SmartConsole (GUI):** Objects pane → **New** → **Host…** → Name `WebServer-01`, IPv4 address `10.0.2.50` → **OK** → click **Publish** (top bar).

**mgmt_cli (CLI):**
```
mgmt_cli -s sid.txt add host name "WebServer-01" ip-address "10.0.2.50"
mgmt_cli -s sid.txt publish
```

**Expected result:** `show-objects` (filter `WebServer-01`, type `host`) returns the object.

**Validation:** `validate-task1-smartconsole.ps1` POSTs `show-objects {type:'host', filter:'WebServer-01'}` and passes when an object named `WebServer-01` is returned.

---

## Exercise 2 / Task 1 — Security Rulebase Management: add rule `Allow-Web`

**Objective:** A published access rule named `Allow-Web` permits http/https to `WebServer-01` (Accept).

**SmartConsole (GUI):** Security Policies → **Access Control → Policy** → select the `Network` layer → **Add rule (bottom)** → Name `Allow-Web`; Destination = `WebServer-01`; Services & Applications = `http`, `https`; Action = **Accept**; (Track = Log recommended) → **Publish** → **Install Policy**.

**mgmt_cli (CLI):**
```
mgmt_cli -s sid.txt add access-rule layer "Network" position bottom name "Allow-Web" \
    destination "WebServer-01" service.1 "http" service.2 "https" action "Accept" track "Log"
mgmt_cli -s sid.txt publish
```

**Expected result:** `show-access-rulebase` for the `Network` layer lists a rule named `Allow-Web`.

**Validation:** `validate-task2-rulebase.ps1` POSTs `show-access-rulebase {name:'Standard Network'}` and passes when a rule named `Allow-Web` exists (top-level or inline).

---

## Exercise 3 / Task 1 — Policy Layering & Application Control: `App-Control` layer

**Objective:** A non-default ordered/inline access layer with **Application & URL Filtering** enabled exists.

**SmartConsole (GUI):** Security Policies → Access Control → **Manage policies and layers** → add an **Inline/Ordered layer** named `App-Control`; in the layer's **Blades**, enable **Applications & URL Filtering** → **OK** → **Publish** → **Install Policy**.

**mgmt_cli (CLI):**
```
mgmt_cli -s sid.txt add access-layer name "App-Control" applications-and-url-filtering "true"
mgmt_cli -s sid.txt publish
```

**Expected result:** `show-access-layers` lists a layer `App-Control` with `applications-and-url-filtering` = `true`.

**Validation:** `validate-task3-policy-layering.ps1` POSTs `show-access-layers` and passes when any layer other than the default `Network` has `applications-and-url-filtering` = `true`.

---

## Exercise 4 / Task 1 — SSH Access Logging & Alerting: Track = Log/Alert

**Objective:** A rule controlling the `ssh` service has Track = Log or Alert.

**SmartConsole (GUI):** In the `Network` layer, find (or add) the rule whose **Service** is `ssh` → right-click its **Track** cell → set to **Log** (or **Alert**) → **Publish** → **Install Policy**.

**mgmt_cli (CLI):**
```
# new rule:
mgmt_cli -s sid.txt add access-rule layer "Network" position bottom name "SSH-Admin" \
    service "ssh" action "Accept" track "Log"
# or change an existing rule's track:
mgmt_cli -s sid.txt set access-rule name "SSH-Admin" layer "Network" track "Alert"
mgmt_cli -s sid.txt publish
```

**Expected result:** `show-access-rulebase` (details-level full) shows the SSH rule with `track.type` = `Log` (or `Alert`).

**Validation:** `validate-task4-ssh-logging.ps1` POSTs `show-access-rulebase {name:'Standard Network', details-level:'full'}` and passes when a rule whose service includes `ssh` has `track.type` of `Log`/`Alert`.

---

## Exercise 5 / Task 1 — Event Analysis (SmartLog / SmartEvent)

**Objective:** Logging is active (≥1 rule tracked) and SmartLog/SmartEvent are used for analysis.

**SmartConsole (GUI):** Ensure at least one rule has **Track = Log/Alert** (Exercise 4 satisfies this). Generate/observe traffic, then open **Logs & Monitor → Logs (SmartLog)** to search the indexed logs, and the **SmartEvent** views/dashboards to correlate events. Note the SSH/web access events.

**mgmt_cli (CLI, proxy check):**
```
mgmt_cli -s sid.txt show-access-rulebase name "Standard Network" details-level "full"
# confirm at least one rule has track.type Log/Alert
```

**Expected result:** SmartLog shows indexed log entries; at least one rule is tracked so logs exist to analyze.

**Validation:** `validate-task5-event-analysis.ps1` POSTs `show-access-rulebase` and passes when ≥1 rule has `track.type` Log/Alert. **SmartLog/SmartEvent analysis itself is GUI and inspection-verified** — the validator only confirms logging/indexing is in place.

---

## Exercise 6 / Task 1 — Compliance Reporting

**Objective:** The Compliance capability is in use and an assessment is available.

**SmartConsole (GUI):** Open **Logs & Monitor → Compliance** (Compliance blade). Run/refresh the assessment, review the **compliance score** and **findings/best-practice** results, and export/observe the report.

**mgmt_cli (CLI, proxy check):**
```
mgmt_cli -s sid.txt show packages
# confirm at least one published policy package exists to assess
```

**Expected result:** The Compliance blade shows a score/report; a published policy package exists.

**Validation:** `validate-task6-compliance.ps1` POSTs `show-packages` and passes when ≥1 policy package exists (best-effort connectivity + published-policy proxy). **The Compliance blade report is GUI-generated and is validated by inspection** — the validator does not score the report itself.

---

### Facilitator Notes

- All six validators run **on the jump VM** via `Invoke-AzVMRunCommand` → `RunPowerShellScript` and call the Management API at `https://10.0.0.10/web_api` (login → show… → logout). HTTP is always `OK`; pass/fail lives in the JSON `Status` field. They are read-only and safe to re-run.
- The candidate **must Publish** (and Install Policy where relevant) before validating — unpublished session changes are not visible to the Management API queries.
- **s1 / s5 / s6** are partly GUI/observational: SmartConsole operation is confirmed via the published object; SmartLog/SmartEvent and the Compliance report are GUI tools whose validators check the closest API proxy (tracked rules / a published package). Confirm those by observation.
- **Licensing & images:** CloudGuard requires a license — the deployment defaults to **PAYG** (`cpImageOffer`/`cpMgmtImageSku`/`cpGwImageSku` = `check-point-cg-r82`/`mgmt-payg`/`sg-payg`). Confirm the exact offer/sku with `az vm image list --publisher checkpoint --all` and accept terms with `az vm image terms accept`.
- Markers (management IP, credentials, package name `Standard`, default layer `Network`, service names) may need tuning to the live Check Point environment.
