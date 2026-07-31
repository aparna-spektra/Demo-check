Import-Module Az.Compute
Import-Module Az.Accounts

# Validation step: f6d5fda1-7e29-4783-ba67-e1825f237f47
# Exercise 2 / Task 1 - Security Rulebase Management: access rule Allow-Web added and published

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
    # task2: confirm a rule named 'Allow-Web' exists in the access rulebase.
    $body = @{ name='Standard Network' } | ConvertTo-Json
    $rb = Invoke-RestMethod -Method Post -Uri "https://$mgmt/web_api/show-access-rulebase" -Headers $h -Body $body -ContentType 'application/json'
    foreach ($r in $rb.rulebase) {
        if ($r.name -eq 'Allow-Web') { $ok = $true }
        if ($r.rulebase) { foreach ($ir in $r.rulebase) { if ($ir.name -eq 'Allow-Web') { $ok = $true } } }
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
                Message = "An access rule named 'Allow-Web' exists in the published Access Control policy."
            } | ConvertTo-Json
        }
        else {
            $message = @{
                Status  = "Failed"
                Message = "No access rule named 'Allow-Web' was found in the rulebase. Add a published rule Allow-Web (http/https to WebServer-01, action Accept)."
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
