# Exercise 5: Event Analysis with SmartLog & SmartEvent

### Estimated Duration: 25 Minutes

## Lab Overview

Check Point logs are indexed and made searchable by **SmartLog**, while **SmartEvent** correlates them into security events and dashboards. None of that is useful unless rules are actually **tracking** their traffic: a policy with no logging produces nothing to analyze. The security team needs logging active across the policy so that SSH access (and other traffic) is available for review in SmartLog/SmartEvent.

This is an **assessment**: the task gives you the **required outcome**, not the exact steps. Ensure tracking is enabled and explore the logs, then press **Validate** to score it.

> **Note:** SmartLog and SmartEvent are **GUI** tools inside SmartConsole. The validator checks the closest API-verifiable proxy — that **tracked rules exist** (logging is enabled) so logs are being indexed for analysis; the SmartLog/SmartEvent inspection itself is confirmed by observation. **Publish** before validating.

## Task 1: Ensure logging is active for event analysis

**Symptom:** No traffic is being logged, so SmartLog shows nothing and SmartEvent has no events to correlate — there is nothing to analyze. No access rule in the policy has tracking enabled.

**Required outcome:** Logging is **active** on the policy and the SmartLog/SmartEvent capability is in use for analysis: **at least one access rule has its Track set to Log or Alert**, so traffic logs are generated and indexed for SmartLog/SmartEvent. The change is **published**. After this task the Management API `show-access-rulebase` returns at least one rule whose `track.type` is `Log` or `Alert`.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="242fc89a-63bb-4d15-8195-42924566b019" />
