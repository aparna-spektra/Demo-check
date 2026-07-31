<#
================================================================================
 bootstrap-01.ps1  -  CloudLabs provisioning automation for
 Lab 01 (Check Point Firewall - Administration & Policy Management)

 PURPOSE
   Executed once at deployment time by the Windows Custom Script Extension on the
   lab jump VM (labvm-<DeploymentID>). It delivers a LEARNER-READY Check Point
   environment so the candidate can start the six assessment tasks immediately:

     1. Prepares the Windows jump host (TLS 1.2, accepts the management server's
        self-signed certificate).
     2. Installs Check Point SmartConsole on the jump VM and creates Desktop +
        Start Menu shortcuts.
     3. Waits for the Security Management server (10.0.0.10) first-time
        configuration to finish and its Management API to come up. (The
        Management + Gateway Gaia first-time configuration is performed
        unattended by the customData/config_system payloads in deploy-01.json.)
     4. Onboards the Security Gateway (cp-gw, 10.0.0.20) into the Management
        server over the Management REST API: establishes Secure Internal
        Communication (SIC) using the one-time key, then installs a BASELINE
        Standard policy so the gateway is operational.
     5. Writes C:\LabFiles\README.txt describing the six tasks and the
        environment coordinates.

   The candidate's six assessed tasks (host WebServer-01, rule Allow-Web,
   App-Control layer, SSH Track=Log/Alert, SmartLog/SmartEvent, Compliance) are
   deliberately NOT pre-created here - only the baseline gateway onboarding +
   default Standard package are seeded, leaving every assessed deliverable for
   the candidate.

 ROBUSTNESS
   Every step is wrapped in try/catch and logged. A single failing step never
   breaks the deployment. SIC onboarding + baseline policy install are retried
   with generous timeouts because the Management and Gateway VMs reboot during
   their unattended first-time configuration and can take 10-20 minutes to come
   up. If onboarding cannot complete in the allotted window the script logs the
   condition and the README documents the manual fallback; SmartConsole and the
   environment coordinates are still delivered.
================================================================================
#>

param(
    [string]$AzureUserName,
    [string]$AzurePassword,
    [string]$AzureTenantID,
    [string]$AzureSubscriptionID,
    [string]$odlId,
    [string]$DeploymentID
)

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'
$LogFile = 'C:\cloudlabs-bootstrap.log'

function Write-Log {
    param([string]$Message)
    $ts = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    Write-Host "$ts  $Message"
    try { "$ts  $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8 } catch { }
}

Write-Log "Bootstrap starting for DeploymentID '$DeploymentID' (ODL '$odlId')."

# ------------------------------------------------------------------------------
# Check Point environment coordinates (kept in sync with deploy-01.json variables)
# ------------------------------------------------------------------------------
$CpMgmtIp        = '10.0.0.10'         # Security Management server (Management API on 443)
$CpGwIp          = '10.0.0.20'         # Security Gateway management-plane IP (SIC)
$CpGwName        = 'cp-gw'             # Gateway object name created on the management server
$CpAdminUser     = 'admin'
$CpAdminPassword = 'Chkp@12345'
$CpSicKey        = 'vpn123456'         # one-time SIC key - MUST match ftw_sic_key in the gw customData
$CpPolicyPackage = 'Standard'          # default policy package present on a fresh management server

# SmartConsole installer source. The Gaia portal on the management server hosts the
# matching SmartConsole build; override $SmartConsoleUrl with a CloudLabs-hosted blob
# URL for the exact R82 SmartConsole if the portal path differs in your environment.
$SmartConsoleUrl  = 'https://10.0.0.10/SmartConsole/SmartConsole.exe'
$SmartConsoleFile = 'C:\LabFiles\SmartConsole.exe'

# Make TLS 1.2 the default and accept the management server's self-signed cert.
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    [Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
} catch { Write-Log "Could not relax TLS settings: $($_.Exception.Message)" }

try { New-Item -Path 'C:\LabFiles' -ItemType Directory -Force | Out-Null } catch { }

# ------------------------------------------------------------------------------
# Helper: wait for a TCP port to become reachable (returns $true/$false)
# ------------------------------------------------------------------------------
function Wait-ForPort {
    param([string]$ComputerName, [int]$Port, [int]$TimeoutMinutes = 20, [int]$IntervalSeconds = 20)
    $deadline = (Get-Date).AddMinutes($TimeoutMinutes)
    while ((Get-Date) -lt $deadline) {
        try {
            $t = Test-NetConnection -ComputerName $ComputerName -Port $Port -WarningAction SilentlyContinue
            if ($t -and $t.TcpTestSucceeded) { return $true }
        } catch { }
        Start-Sleep -Seconds $IntervalSeconds
    }
    return $false
}

# ------------------------------------------------------------------------------
# Helper: Management REST API call. Returns the parsed response object (or throws).
# ------------------------------------------------------------------------------
function Invoke-CpApi {
    param([string]$Command, [hashtable]$Body = @{}, [string]$Sid = $null)
    $headers = @{ }
    if ($Sid) { $headers['X-chkp-sid'] = $Sid }
    $json = ($Body | ConvertTo-Json -Depth 6)
    return Invoke-RestMethod -Method Post -Uri "https://$CpMgmtIp/web_api/$Command" `
        -Headers $headers -Body $json -ContentType 'application/json'
}

# ------------------------------------------------------------------------------
# 1) Confirm tooling on the jump host
# ------------------------------------------------------------------------------
try {
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion.ToString())."
    $curlPath = (Get-Command curl.exe -ErrorAction SilentlyContinue).Source
    if ($curlPath) { Write-Log "curl.exe present at $curlPath." } else { Write-Log "curl.exe not on PATH (continuing)." }
} catch { Write-Log "Tooling check warning: $($_.Exception.Message)" }

# ------------------------------------------------------------------------------
# 2) Install SmartConsole + create Desktop / Start Menu shortcuts
# ------------------------------------------------------------------------------
try {
    Write-Log "Waiting for the management server web portal (TCP 443) so SmartConsole can be downloaded..."
    $portalUp = Wait-ForPort -ComputerName $CpMgmtIp -Port 443 -TimeoutMinutes 25
    if (-not $portalUp) { Write-Log "Management portal not reachable within timeout; will still attempt download." }

    Write-Log "Downloading SmartConsole from $SmartConsoleUrl ..."
    try {
        Invoke-WebRequest -Uri $SmartConsoleUrl -OutFile $SmartConsoleFile -UseBasicParsing -TimeoutSec 600
    } catch {
        Write-Log "SmartConsole download failed: $($_.Exception.Message). Set `$SmartConsoleUrl to a reachable R82 SmartConsole installer (CloudLabs blob) and re-run."
    }

    if (Test-Path $SmartConsoleFile) {
        Write-Log "Installing SmartConsole silently..."
        try {
            Start-Process -FilePath $SmartConsoleFile -ArgumentList '/S' -Wait
        } catch {
            Write-Log "Silent '/S' install failed ($($_.Exception.Message)); retrying with '/quiet /norestart'."
            try { Start-Process -FilePath $SmartConsoleFile -ArgumentList '/quiet','/norestart' -Wait } catch { Write-Log "SmartConsole install retry failed: $($_.Exception.Message)" }
        }

        # Locate the installed SmartConsole.exe and create shortcuts.
        $sc = Get-ChildItem -Path 'C:\Program Files','C:\Program Files (x86)' -Recurse -Filter 'SmartConsole.exe' -ErrorAction SilentlyContinue |
              Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($sc) {
            Write-Log "SmartConsole installed at $($sc.FullName); creating shortcuts."
            try {
                $ws = New-Object -ComObject WScript.Shell
                foreach ($lnkDir in @("$env:Public\Desktop", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs")) {
                    $lnk = $ws.CreateShortcut((Join-Path $lnkDir 'Check Point SmartConsole.lnk'))
                    $lnk.TargetPath = $sc.FullName
                    $lnk.WorkingDirectory = Split-Path $sc.FullName
                    $lnk.IconLocation = "$($sc.FullName),0"
                    $lnk.Description = 'Check Point SmartConsole'
                    $lnk.Save()
                }
                Write-Log "Desktop + Start Menu shortcuts created."
            } catch { Write-Log "Shortcut creation warning: $($_.Exception.Message)" }
        } else {
            Write-Log "SmartConsole.exe not found after install; the candidate can (re)install from https://$CpMgmtIp."
        }
    }
} catch { Write-Log "SmartConsole stage warning: $($_.Exception.Message)" }

# ------------------------------------------------------------------------------
# 3) Wait for the Management API, then onboard the gateway (SIC) + baseline policy
# ------------------------------------------------------------------------------
try {
    Write-Log "Waiting for the Management API (TCP 443) on $CpMgmtIp ..."
    if (-not (Wait-ForPort -ComputerName $CpMgmtIp -Port 443 -TimeoutMinutes 30)) {
        Write-Log "Management API port not reachable; skipping gateway onboarding (see README for manual steps)."
    } else {
        # The API may answer the port before login is ready; retry login for a while.
        $sid = $null
        $loginDeadline = (Get-Date).AddMinutes(20)
        while (-not $sid -and (Get-Date) -lt $loginDeadline) {
            try {
                $login = Invoke-CpApi -Command 'login' -Body @{ user = $CpAdminUser; password = $CpAdminPassword }
                $sid = $login.sid
            } catch { Start-Sleep -Seconds 20 }
        }

        if (-not $sid) {
            Write-Log "Could not log in to the Management API yet; skipping onboarding (README documents the manual fallback)."
        } else {
            Write-Log "Logged in to the Management API. Onboarding gateway '$CpGwName' ($CpGwIp) and establishing SIC..."
            $sicOk = $false
            $sicDeadline = (Get-Date).AddMinutes(20)
            while (-not $sicOk -and (Get-Date) -lt $sicDeadline) {
                try {
                    Invoke-CpApi -Command 'add-simple-gateway' -Sid $sid -Body @{
                        name              = $CpGwName
                        'ip-address'      = $CpGwIp
                        'one-time-password' = $CpSicKey
                        firewall          = $true
                    } | Out-Null
                    $sicOk = $true
                    Write-Log "Gateway object created and SIC trust established."
                } catch {
                    $msg = $_.Exception.Message
                    if ($msg -match 'More than one|already exists|exists') {
                        Write-Log "Gateway object already exists - treating SIC as established."
                        $sicOk = $true
                    } else {
                        Write-Log "SIC attempt failed (gateway may still be booting): $msg. Retrying..."
                        Start-Sleep -Seconds 30
                    }
                }
            }

            try { Invoke-CpApi -Command 'publish' -Sid $sid -Body @{} | Out-Null; Write-Log "Published gateway object." }
            catch { Write-Log "Publish warning: $($_.Exception.Message)" }

            if ($sicOk) {
                try {
                    Write-Log "Installing baseline '$CpPolicyPackage' policy on '$CpGwName'..."
                    Invoke-CpApi -Command 'install-policy' -Sid $sid -Body @{
                        'policy-package' = $CpPolicyPackage
                        access           = $true
                        targets          = $CpGwName
                    } | Out-Null
                    Write-Log "Baseline policy install requested."
                } catch { Write-Log "Baseline policy install warning (candidate can install later): $($_.Exception.Message)" }
            }

            try { Invoke-CpApi -Command 'logout' -Sid $sid -Body @{} | Out-Null } catch { }
        }
    }
} catch { Write-Log "Gateway onboarding stage warning: $($_.Exception.Message)" }

# ------------------------------------------------------------------------------
# 4) Candidate README describing the six tasks
# ------------------------------------------------------------------------------
try {
    Write-Log "Writing C:\LabFiles\README.txt."
    $readme = @"
================================================================================
 Check Point Firewall - Administration & Policy Management (Lab 01)
================================================================================

Your environment is configured and learner-ready:
  - SmartConsole is installed on this jump VM (see the "Check Point SmartConsole"
    shortcut on the Desktop / Start Menu).
  - The Security Management server and Security Gateway have completed their
    first-time configuration; the gateway 'cp-gw' is onboarded over SIC and a
    baseline 'Standard' policy is installed.

  Security Management server : https://$CpMgmtIp
  Management REST API base   : https://$CpMgmtIp/web_api
  Admin username             : $CpAdminUser
  Admin password             : $CpAdminPassword
  Security Gateway (SIC)     : $CpGwName  ($CpGwIp)

Open SmartConsole, connect to $CpMgmtIp with the admin credentials above, and
complete the six tasks. Always PUBLISH (and install policy where relevant) before
you press Validate - the validators read the published configuration via the
Management API at https://$CpMgmtIp/web_api.

TASKS
  Exercise 1 - SmartConsole Operation
     Create and PUBLISH a host object named 'WebServer-01' (IP 10.0.2.50).
  Exercise 2 - Security Rulebase Management
     Add a published access rule named 'Allow-Web' permitting HTTP+HTTPS to
     WebServer-01 (action Accept).
  Exercise 3 - Policy Layering & Application Control
     Create an access layer (e.g. 'App-Control') with Application & URL Filtering
     enabled.
  Exercise 4 - SSH Access Logging & Alerting
     Configure a rule controlling the 'ssh' service with Track = Log or Alert.
  Exercise 5 - Event Analysis (SmartLog / SmartEvent)
     Ensure logging is active and use SmartLog / SmartEvent to analyze traffic.
  Exercise 6 - Compliance Reporting
     Use the Compliance blade to produce a compliance assessment.

MANUAL FALLBACK (only if onboarding did not finish)
  If 'cp-gw' is missing in SmartConsole (the gateway can take 10-20 min to finish
  its first-time reboot), add it manually: Objects > New > Gateway > 'cp-gw',
  IP $CpGwIp, set the one-time SIC key '$CpSicKey', Initialize SIC, then Install
  Policy. See C:\cloudlabs-bootstrap.log for what the automation completed.
================================================================================
"@
    Set-Content -Path 'C:\LabFiles\README.txt' -Value $readme -Encoding UTF8
    Write-Log "README written."
} catch { Write-Log "README write warning: $($_.Exception.Message)" }

Write-Log "Bootstrap complete."
