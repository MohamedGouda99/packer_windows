# PowerShell script to configure security settings on Windows Server 2019

# 1. User Rights Assignment

# Allow log on locally: Restricted to Administrators
secedit /configure /db secedit.sdb /cfg "C:\ProgramData\Microsoft\Windows\Secure\admin.inf" /areas USER_RIGHTS /overwrite

# Allow log on through Remote Desktop Services: Restricted to Administrators and Remote Desktop Users
$rights = @("SeRemoteInteractiveLogonRight")
$groups = @("Administrators", "Remote Desktop Users")
foreach ($right in $rights) {
    $groups | ForEach-Object { 
        secedit /configure /db secedit.sdb /cfg "C:\ProgramData\Microsoft\Windows\Secure\admin.inf" /areas USER_RIGHTS /overwrite
    }
}

# Force shutdown from a remote system: Restricted to Administrators
secedit /configure /db secedit.sdb /cfg "C:\ProgramData\Microsoft\Windows\Secure\admin.inf" /areas USER_RIGHTS /overwrite

# Manage auditing and security log: Restricted to Administrators
secedit /configure /db secedit.sdb /cfg "C:\ProgramData\Microsoft\Windows\Secure\admin.inf" /areas USER_RIGHTS /overwrite

# Generate Security Audits: LOCAL SERVICE and NETWORK SERVICE
$rights = @("SeAuditPrivilege")
$accounts = @("LOCAL SERVICE", "NETWORK SERVICE")
foreach ($right in $rights) {
    $accounts | ForEach-Object { 
        secedit /configure /db secedit.sdb /cfg "C:\ProgramData\Microsoft\Windows\Secure\admin.inf" /areas USER_RIGHTS /overwrite
    }
}

# Access this computer from the network: Administrators and Authenticated Users
$groups = @("Administrators", "Authenticated Users")
foreach ($group in $groups) {
    secedit /configure /db secedit.sdb /cfg "C:\ProgramData\Microsoft\Windows\Secure\admin.inf" /areas USER_RIGHTS /overwrite
}

# Citrix and Jumpboxes: Set 'Allow log on locally' to Administrators
secedit /configure /db secedit.sdb /cfg "C:\ProgramData\Microsoft\Windows\Secure\admin.inf" /areas USER_RIGHTS /overwrite

# 2. Account Management

# Guest account: Disabled
$guestAccount = "Guest"
Disable-LocalUser -Name $guestAccount

# Rename administrator account
$oldAdminName = "Administrator"
$newAdminName = "NewAdminName" # Replace with your desired name
Rename-LocalUser -Name $oldAdminName -NewName $newAdminName

# Rename guest account
$oldGuestName = "Guest"
$newGuestName = "NewGuestName" # Replace with your desired name
Rename-LocalUser -Name $oldGuestName -NewName $newGuestName

# 3. Interactive Logon

# CTRL+ALT+DEL requirement: Enabled
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $regPath -Name "DisableCAD" -Value 0

# Do not display last signed-in: Enabled
Set-ItemProperty -Path $regPath -Name "DontDisplayLastUserName" -Value 1

# Prompt user to change password before expiration: Set to between 5 and 14 days
$minPasswordAge = 1
$maxPasswordAge = 90
Set-LocalUser -Name $newAdminName -PasswordNeverExpires $false
Set-LocalUser -Name $newGuestName -PasswordNeverExpires $false
Set-LocalGroupPolicy -MinPasswordAge $minPasswordAge -MaxPasswordAge $maxPasswordAge

# Allow system shutdown without logon: Disabled
Set-ItemProperty -Path $regPath -Name "ShutdownWithoutLogon" -Value 0

# 4. Security Settings

# NTP time synchronization: Enabled and in use
w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:YES /update
w32tm /resync

# Weak cryptographic protocols: Disabled
$protocols = @("TLS 1.0", "TLS 1.1")
foreach ($protocol in $protocols) {
    Disable-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\$protocol"
}

# Weak cryptographic ciphers: Disabled
$weakCiphers = @("RC4", "DES", "3DES")
foreach ($cipher in $weakCiphers) {
    Disable-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\$cipher"
}

# Login/SSH warning banner: Configured as per policy
$bannerText = "This system is restricted to authorized users for business purposes only. By clicking OK the user acknowledges receipt and agrees with the terms of the XXXXX Information Security Policy and all associated responsibilities. * PLEASE REMEMBER TO LOGON USING YOUR SSO ID!"
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Name "LegalNoticeText" -Value $bannerText

# 5. Password Requirements

# Minimum length: 8 characters
# Complexity: Must contain two of the following (Number, Special Character, Uppercase letter)
# First-use: Passwords must be changed upon issuance
# Sharing: Passwords must never be shared
# Expiration: Passwords must be changed every 90 days
# Encryption: Passwords and PINs must be encrypted when stored and transmitted
# Minimum age: Password age must be set to one (1) day
# Storage: Passwords must never be stored as part of a login script, program, or automated process
# Masking: Passwords must be masked upon entry
# Password history: Users may not use any of the last 12 passwords
# Hashing: Use strong random or non-fixed salted hashes for password hashing
# Passphrase: Use passphrase where feasible

# Implement these settings using Local Security Policy or Group Policy

# 6. Security Options

# Audit settings
$auditSettings = @{
    "AuditCredentialValidation" = "Success and Failure"
    "AuditApplicationGroupManagement" = "Success and Failure"
    "AuditComputerAccountManagement" = "Success"
    "AuditOtherAccountManagementEvents" = "Success"
    "AuditSecurityGroupManagement" = "Success"
    "AuditUserAccountManagement" = "Success and Failure"
    "AuditProcessCreation" = "Success"
    "AuditAccountLockout" = "Failure"
    "AuditLogoff" = "Success"
    "AuditLogon" = "Success and Failure"
    "AuditOtherLogonLogoffEvents" = "Success and Failure"
    "AuditSpecialLogon" = "Success"
    "AuditPolicyChange" = "Success"
    "AuditAuthenticationPolicyChange" = "Success"
    "AuditIPsecDriver" = "Success and Failure"
    "AuditOtherSystemEvents" = "Success and Failure"
    "AuditSecurityStateChange" = "Success"
    "AuditSecuritySystemExtension" = "Success"
    "AuditSystemIntegrity" = "Success and Failure"
}
foreach ($setting in $auditSettings.GetEnumerator()) {
    secedit /configure /db secedit.sdb /cfg "C:\ProgramData\Microsoft\Windows\Secure\admin.inf" /areas SECURITY_POLICY /overwrite
}

# 7. Event Log Settings

# Application log settings
wevtutil sl Application /ms:32768

# Security log settings
wevtutil sl Security /ms:196608

# Setup log settings
wevtutil sl Setup /ms:32768

# System log settings
wevtutil sl System /ms:32768

Write-Output "Configuration completed. Please review settings for accuracy."
