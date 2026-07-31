# Exercise 6: Compliance Reporting

### Estimated Duration: 25 Minutes

## Lab Overview

Check Point's **Compliance** software blade continuously assesses the management and gateway configuration against security best practices and regulatory standards, producing a compliance score and a report of findings. The security team needs a compliance assessment of the environment so gaps can be tracked and remediated.

This is an **assessment**: the task gives you the **required outcome**, not the exact steps. Generate the assessment in SmartConsole, then press **Validate** to score it.

> **Note:** The Compliance blade report is **GUI-generated** inside SmartConsole (the Compliance / Logs & Monitor views). The validator performs a **best-effort** API check — confirming the Management API is reachable and a **published policy package exists** — and the compliance report itself is confirmed by inspection. **Publish** before validating.

## Task 1: Produce a compliance assessment of the environment

**Symptom:** No compliance assessment of the Check Point environment has been produced, so the team has no view of its compliance posture or findings.

**Required outcome:** The **Compliance** capability is in use and a **compliance assessment is available** for the environment (run the Compliance blade and review the resulting report/score). As the API-verifiable proxy, the Management API is reachable and a **published policy package** exists for the gateway to be assessed against. After this task the Management API `show-packages` returns at least one policy package and the compliance report has been generated for review.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="5d415860-c244-4aac-a768-33075883eb83" />
