[CloudLabs Validator](https://spektra-systems.visualstudio.com/CloudLabs-Validator)

Lab Code: CHECKPOINTFW

> Validations for this assessment run **on the Windows jump VM** (via `Invoke-AzVMRunCommand` →
> `RunPowerShellScript`) and call the **Check Point Management REST API** at
> `https://10.0.0.10/web_api` (login → `sid` → `show-objects` / `show-access-rulebase` /
> `show-access-layers` / `show-packages` → logout). They require the **Management API to be enabled
> for the jump host** and the correct **admin credentials** (admin / `Chkp@12345`). Some scenarios are
> partly **GUI-based and inspection-verified**: Exercise 1 (SmartConsole operation) is confirmed via the
> object it publishes, while Exercise 5 (SmartLog/SmartEvent) and Exercise 6 (Compliance blade report)
> are GUI tools — their validators check the closest API-verifiable proxy (tracked rules / a published
> policy package) and the analysis/report itself is inspection-verified. Each validator retries up to 3
> times (`Start-Sleep -Seconds 10`), always returns HTTP `OK`, and carries the pass/fail in the JSON
> `Status` field (`Succeeded`/`Failed`) based on the in-VM sentinel `Validation Success`.

| Task | Validation step UUID | Script |
|---|---|---|
| Exercise 1 / Task 1 — SmartConsole Operation (publish host `WebServer-01`) | bfce4926-377f-44ad-b107-f1bb61a2dc1e | validate-task1-smartconsole.ps1 |
| Exercise 2 / Task 1 — Security Rulebase Management (rule `Allow-Web`) | f6d5fda1-7e29-4783-ba67-e1825f237f47 | validate-task2-rulebase.ps1 |
| Exercise 3 / Task 1 — Policy Layering & Application Control (layer with App & URL Filtering) | 760f3727-cd1d-4037-8d5c-4e75f3b31d85 | validate-task3-policy-layering.ps1 |
| Exercise 4 / Task 1 — SSH Access Logging & Alerting (SSH rule Track = Log/Alert) | 00267005-56b0-4fc9-95c3-20bb535edf67 | validate-task4-ssh-logging.ps1 |
| Exercise 5 / Task 1 — Event Analysis SmartLog/SmartEvent (logging active) | 242fc89a-63bb-4d15-8195-42924566b019 | validate-task5-event-analysis.ps1 |
| Exercise 6 / Task 1 — Compliance Reporting (Compliance in use / policy package) | 5d415860-c244-4aac-a768-33075883eb83 | validate-task6-compliance.ps1 |
