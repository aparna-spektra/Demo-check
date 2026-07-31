Import-Module Az.Compute
Import-Module Az.Accounts

# Validation step: bfce4926-377f-44ad-b107-f1bb61a2dc1e
# Exercise 1 / Task 1 - SmartConsole Operation: host object WebServer-01 created and published

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
    # task1: confirm a published host object named WebServer-01 exists.
    $body = @{ type='host'; filter='WebServer-01' } | ConvertTo-Json
    $objs = Invoke-RestMethod -Method Post -Uri "https://$mgmt/web_api/show-objects" -Headers $h -Body $body -ContentType 'application/json'
    foreach ($o in $objs.objects) { if ($o.name -eq 'WebServer-01') { $ok = $true } }

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
                Message = "A host object named 'WebServer-01' exists and is published in the Check Point management database."
            } | ConvertTo-Json
        }
        else {
            $message = @{
                Status  = "Failed"
                Message = "No published host object named 'WebServer-01' was found. In SmartConsole create a host WebServer-01 (10.0.2.50) and Publish the session."
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
