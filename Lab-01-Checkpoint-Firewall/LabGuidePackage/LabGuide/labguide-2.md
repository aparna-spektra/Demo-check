# Exercise 2: Security Rulebase Management — Add an Access Rule

### Estimated Duration: 25 Minutes

## Lab Overview

The Check Point **access rulebase** (the Access Control policy) decides which traffic the gateway permits or drops, matched top-down on source, destination, service and application. With the new web-server object in place, the security team needs an explicit rule that allows web traffic to it — instead of relying on the implicit cleanup drop.

This is an **assessment**: the task gives you the **required outcome**, not the exact steps. Add the rule in SmartConsole, **Publish** (and install policy), then press **Validate** to score it.

> **Note:** Edit the Access Control policy in SmartConsole (or via the Management API), then **Publish** your session. The validator reads the published rulebase via the Management API.

## Task 1: Add a published access rule named `Allow-Web`

**Symptom:** There is no access rule that permits web traffic to the new web server. The rulebase contains no rule named `Allow-Web`, so HTTP/HTTPS to `WebServer-01` would only ever hit the implicit cleanup drop.

**Required outcome:** A **security access rule** named **`Allow-Web`** exists in the Access Control policy and has been **published**. The rule permits web traffic (for example services **http** and **https**) to **`WebServer-01`** with **action Accept**. After this task the Management API `show-access-rulebase` returns a rule whose name is `Allow-Web`.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="f6d5fda1-7e29-4783-ba67-e1825f237f47" />
