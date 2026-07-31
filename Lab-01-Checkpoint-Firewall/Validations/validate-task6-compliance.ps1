Import-Module Az.Compute
Import-Module Az.Accounts

# Validation step: 5d415860-c244-4aac-a768-33075883eb83
# Exercise 6 / Task 1 - Compliance Reporting: Compliance capability in use (best-effort: API reachable + policy package exists)

# Variables provided by CloudLabs
$deployment_id     = $deployment_id
$resourceGroupName = $resourceGroupName
$sub_id            = $sub_id
$vmName            = "labvm-$deployment_id"

# Set subscription
Select-AzSubscription -SubscriptionId $sub_id

# Retry logic
$stopRetry = $false
[int]$retryCount = 0
$maxRetries = 3

do {
    try {

        # PowerShell script to run inside the Windows jump VM. It reaches the
        # Check Point Management API and must Write-Output exactly the sentinel
        # "Validation Success" (only when the check passes) or "Validation Failed".
        $script = @'
# NOTE: The management IP (10.0.0.10), admin credentials (admin / Chkp@12345)
# and the API object/rulebase/layer names below may need tuning to match the
# live Check Point environment for this ODL.
$mgmt='10.0.0.10'; $u='admin'; $p='Chkp@12345'
[Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
try {
    $login = Invoke-RestMethod -Method Post -Uri "https://$mgmt/web_api/login" -Body (@{user=$u;password=$p}|ConvertTo-Json) -ContentType 'application/json'
    $sid = $login.sid
    $h = @{ 'X-chkp-sid' = $sid }
    $ok = $false
    # task6: best-effort proxy. NOTE: The Compliance blade report is GUI-generated in
    # SmartConsole and is validated by INSPECTION. This check only confirms the
    # Management API is reachable and a published policy package exists for the
    # gateway to be assessed against - it does not score the compliance report itself.
    $pkgs = Invoke-RestMethod -Method Post -Uri "https://$mgmt/web_api/show-packages" -Headers $h -Body '{}' -ContentType 'application/json'
    if ($pkgs.packages -and (@($pkgs.packages).Count -ge 1)) { $ok = $true }

    Invoke-RestMethod -Method Post -Uri "https://$mgmt/web_api/logout" -Headers $h -Body '{}' -ContentType 'application/json' | Out-Null
    if ($ok) { Write-Output 'Validation Success' } else { Write-Output 'Validation Failed' }
} catch { Write-Output 'Validation Failed' }
'@

        # Execute inside VM
        $result = Invoke-AzVMRunCommand `
            -ResourceGroupName $resourceGroupName `
            -VMName $vmName `
            -CommandId "RunPowerShellScript" `
            -ScriptString $script

        $vmOutput = ($result.Value[0].Message | Out-String).Trim()

        if ($vmOutput -match "Validation Success") {
            $message = @{
                Status  = "Succeeded"
                Message = "The Management API is reachable and a published policy package exists for compliance assessment (Compliance report inspection-verified)."
            } | ConvertTo-Json
        }
        else {
            $message = @{
                Status  = "Failed"
                Message = "Could not confirm a published policy package via the Management API. Ensure the management API is reachable and a policy package exists, then run the Compliance report."
            } | ConvertTo-Json
        }

        # Return JSON response
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [System.Net.HttpStatusCode]::OK
            Body       = $message
        })

        $stopRetry = $true
    }
    catch {
        if ($retryCount -ge $maxRetries) {
            $message = @{
                Status  = "Failed"
                Message = "Retry for validation process has been exhausted. Please try after sometime."
            } | ConvertTo-Json

            Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode = [System.Net.HttpStatusCode]::OK
                Body       = $message
            })

            $stopRetry = $true
        }
        else {
            Write-Host "Validation failed. Retrying... ($($retryCount + 1)/$maxRetries)"
            Start-Sleep -Seconds 10
            $retryCount++
        }
    }
} while ($stopRetry -eq $false)
