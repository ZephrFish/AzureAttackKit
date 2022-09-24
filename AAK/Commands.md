## Microburst
---------------
- Invoke-AzVMBulkCMD (Az function)
- Get-AzureVMExtensionSettings.ps1 (misc function)
- Invoke-AzVMCommandREST (Rest function)
	- needs mgmt token
	
## PowerZure
---------------
- Set-AzureSubscription
- Get-AzureUser -Username
- Show-AzureCurrentUser
- Invoke-AzureRunCommand

## AADInternals 
### Note for all IntRecon
- Get-AADIntAccessTokenForAzureCoreManagement -SaveToCache
- InvokeAADIntReconAsInsider
- InvokeAADIntReconAsGuest

```
$results = Invoke-AADIntReconAsInsider
$resultsGuest = InvokeAADIntReconAsGuest
```

## AzureRT
-------------------
- Get-ARTWhoami
- Get-ArtAccessTokenAzCli / Get-ARTAccessTokenAz
- Get-ARTDangerousPermissions
- Get-ARTResource
- Get-ARTRoleAssignment
- Get-ARTADScopedRoleAssignment
- Get-ARTADDynamicGroups
- Get-ARTAzVMPublicIP
- Get-ARTAzVMUserDataFromInside
- Invoke-ARTRunCommand (virtualMachines/runCommand abuse)
- Invoke-ARTCustomScriptExtension
- Get-ARTTenantID
- Get-ARTPRTToken
- Get-ARTSubscriptionID
- Invoke-ARTGETRequest

Function
```
Install-Module Az -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module AzureAD -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module Microsoft.Graph -Force -Confirm -AllowClobber -Scope CurrentUser 
Install-Module MSOnline -Force -Confirm -AllowClobber -Scope CurrentUser        
Install-Module AzureADPreview -Force -Confirm -AllowClobber -Scope CurrentUser  
Install-Module AADInternals -Force -Confirm -AllowClobber -Scope CurrentUser    

# Import All The Modules
Import-Module Az
Import-Module AzureAD
Import-Module .\MicroBurst-master\MicroBurst.psm1
Import-Module .\AzureRT-master\AzureRT.ps1
Import-Module AADInternals

$enabledSubs = Get-AzSubscription  |  Where-Object{$_.State -eq "Enabled"} | select Id
foreach ($SubName in $enabledSubs) {    
    $IDOut = $SubName.id
    echo $SubName.Name >> Subscriptions.txt
    Set-AzContext -Subscription "$IDOut"
    Invoke-AzHybridWorkerExtraction -Subscription $IDOut | Out-File "$IDOut_Hybrid.txt"
    Get-AzKeyVaultsAutomation -Subscription $IDOut | Out-File "$IDOut_AutomationAcc.txt"
    Get-AzDomainInfo -Subscription $IDOut -Users N -Groups N | Out-File "$IDOut_DomainInfoMB.txt"
    Get-ARTWhoami -Verbose | Out-File "$IDOut_ARTWHOAMI.txt"
    Get-ARTAccess -SubscriptionId $IDOut | Out-File "$IDOut_ARTAccess.txt"
    Get-ARTApplication | Out-File "$IDOut_ARTApplication.txt"
    Get-ARTStorageAccountKeys -Verbose | Out-File "$IDOut_ARTStorageAccountKeys.txt"
}


```
