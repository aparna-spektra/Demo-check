# Exercise 4: SSH Access Logging & Alerting Configuration

### Estimated Duration: 25 Minutes

## Lab Overview

Administrative protocols such as **SSH** must be auditable. On Check Point, each access rule has a **Track** setting that controls whether matching traffic is logged — values include **None**, **Log**, and **Alert** (Alert both logs and raises a notification). The security team wants SSH access to be recorded so it can be reviewed and alerted on.

This is an **assessment**: the task gives you the **required outcome**, not the exact steps. Configure the rule's tracking in SmartConsole, **Publish**, then press **Validate** to score it.

> **Note:** Identify (or create) the access rule that controls **SSH** (service `ssh`), set its **Track** to **Log** or **Alert**, then **Publish**. The validator inspects the rule's track setting via the Management API.

## Task 1: Track SSH access with Log or Alert

**Symptom:** SSH access is not being recorded. The access rule that controls the `ssh` service has its **Track** set to **None**, so SSH connections produce no logs or alerts and cannot be reviewed.

**Required outcome:** A **security access rule** whose service includes **`ssh`** has its **Track** set to **Log** or **Alert** (so SSH access is logged/alerted), and the change has been **published**. After this task the Management API `show-access-rulebase` (details-level full) returns a rule matching the `ssh` service whose `track.type` is `Log` or `Alert`.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="00267005-56b0-4fc9-95c3-20bb535edf67" />
