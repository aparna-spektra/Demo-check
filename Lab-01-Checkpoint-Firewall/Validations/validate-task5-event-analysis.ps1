Import-Module Az.Compute
Import-Module Az.Accounts

# Validation step: 242fc89a-63bb-4d15-8195-42924566b019
# Exercise 5 / Task 1 - Event Analysis (SmartLog/SmartEvent): logging active (at least one tracked rule)

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
    # task5: proxy that logging is enabled (>=1 rule tracked Log/Alert) so SmartLog/
    # SmartEvent have logs to analyze. NOTE: SmartLog and SmartEvent are GUI tools in
    # SmartConsole; the actual event analysis is inspection-verified. This API check
    # only confirms tracked rules / log indexing exist.
    $body = @{ name='Standard Network'; 'details-level'='full' } | ConvertTo-Json
    $rb = Invoke-RestMethod -Method Post -Uri "https://$mgmt/web_api/show-access-rulebase" -Headers $h -Body $body -ContentType 'application/json'
    foreach ($r in $rb.rulebase) {
        $tt = if ($r.track.type) { "$($r.track.type)" } else { "$($r.track)" }
        if ($tt -match 'Log' -or $tt -match 'Alert') { $ok = $true }
    }

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
                Message = "At least one access rule has Track = Log/Alert, so logs are indexed for SmartLog/SmartEvent analysis."
            } | ConvertTo-Json
        }
        else {
            $message = @{
                Status  = "Failed"
                Message = "No access rule has tracking enabled, so there are no logs to analyze in SmartLog/SmartEvent. Enable Log/Alert tracking on at least one rule and Publish."
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
