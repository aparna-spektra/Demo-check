# Exercise 3: Policy Layering & Application Control

### Estimated Duration: 25 Minutes

## Lab Overview

Check Point policies can be split into **layers** — ordered or inline collections of rules that are evaluated in sequence. A layer can have specific software blades enabled on it; turning on **Application & URL Filtering** (Application Control) on a layer lets rules match on application and URL categories, not just ports. The security team wants application-aware control added to the policy through a dedicated layer.

This is an **assessment**: the task gives you the **required outcome**, not the exact steps. Create the layer in SmartConsole, **Publish**, then press **Validate** to score it.

> **Note:** Add an ordered or inline access layer to the policy package and enable **Application & URL Filtering** on it, then **Publish**. The validator reads the access layers via the Management API.

## Task 1: Create an access layer with Application & URL Filtering enabled

**Symptom:** The policy has only the default access layer, and it does not perform application-aware filtering. There is no additional layer on which **Application & URL Filtering** is enabled, so rules cannot match on application/URL categories.

**Required outcome:** An **ordered or inline access layer** (other than the default layer) — for example **`App-Control`** — exists in the policy with **Application & URL Filtering enabled** (the layer's `applications-and-url-filtering` setting is `true`), and the change has been **published**. After this task the Management API `show-access-layers` returns a non-default layer with `applications-and-url-filtering` = `true`.

> **Congratulations** on completing the task! Now, it's time to validate it. Here are the steps:
> - Hit the Validate button for the corresponding task. If you receive a success message, you can proceed to the next task.
> - If not, carefully read the error message and retry the step, following the instructions in the lab guide.
> - If you need any assistance, please contact us at cloudlabs-support@spektrasystems.com. We are available 24/7 to help you out.

<validation step="760f3727-cd1d-4037-8d5c-4e75f3b31d85" />
