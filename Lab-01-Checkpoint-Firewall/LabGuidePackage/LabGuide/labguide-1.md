# Exercise 1: SmartConsole Operation — Create and Publish an Object

### Estimated Duration: 25 Minutes

## Lab Overview

SmartConsole is the unified Check Point management client. Everything an administrator does — defining objects, editing the rulebase, installing policy — happens inside a SmartConsole **session** that must be **published** before the changes become part of the management database. The first thing the security team needs is a network object representing a new internal web server so it can be referenced by policy.

This is an **assessment**: the task gives you the **symptom and the required outcome**, not the click-by-click steps. Build it in SmartConsole, **Publish** the session, then press **Validate** to score it.

> **Note:** Open SmartConsole on the jump VM and connect to the management server at `10.0.0.10` (admin / `Chkp@12345`). You **must Publish** your session before validating — the validator reads the published management database via the Management API.

## Task 1: Create and publish a host object named `WebServer-01`

**Symptom:** There is no object in the management database that represents the new internal web server, so no rule can reference it. SmartConsole shows no host named `WebServer-01`.

**Required outcome:** Using SmartConsole, a **host object** named **`WebServer-01`** with IP address **`10.0.2.50`** exists in the management database, and the session that created it has been **published**. After this task the Management API `show-objects` returns an object named `WebServer-01`.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="bfce4926-377f-44ad-b107-f1bb61a2dc1e" />
