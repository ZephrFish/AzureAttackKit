# AzureAttackKit
Collection of Azure Tools to Pull down for Attacking an Env from a windows machine or Cloudshell. 

## Pre-Requisites
Git for Windows if you want to auto pull down the latest versions of everything via powershell.

## Setup
Setup.ps1 contains the following lines to install the required modules to access azure and the various assocated modules. 
```
Install-Module Az -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module AzureAD -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module Microsoft.Graph -Force -Confirm -AllowClobber -Scope CurrentUser
Install-Module MSOnline -Force -Confirm -AllowClobber -Scope CurrentUser       
Install-Module AzureADPreview -Force -Confirm -AllowClobber -Scope CurrentUser 
Install-Module AADInternals -Force -Confirm -AllowClobber -Scope CurrentUser   

Import-Module Az
Import-Module AzureAD
```

Once the modules are installed you will need to connect an Azure account using the following three commands (if you're on Cloudshell use Connect-AzAccount -UseDeviceAuthentication): 
## Setup:
`. .\Setup.ps1`
`Connect-ADandAZ`

If the above fails run the following:
``` 
Connect-AzAccount
Connect-AzureAD
Connect-MSolService
```

## Included Tools
- PowerZure + Cloudshell
- AzureHound
- AzureRT
- MicroBurst
- AADInternals

## Quick Wins
Pull all the subscriptions you have access to then iterate through them, change Get-ARTAccess(Which uses AzureRT) to whatever tool you want to run across the subscription.
```
$enabledSubs = Get-AzSubscription |  Where-Object{$_.State -eq "Enabled"} | select Id
foreach ($SubName in $enabledSubs) {
    $IDOut = $SubName.id
    Get-ARTAccess -SubscriptionID $IDOut | Out-File "$IDOut.txt"
}
```

Use PowerZure to pull runbook content for each sub:
```
$enabledSubs = Get-AzSubscription |  Where-Object{$_.State -eq "Enabled"} | select Id
foreach ($SubName in $enabledSubs) {    
    $IDOut = $SubName.id
    Set-AzContext -Subscription "$IDOut"
    Get-AzureRunbookContent -All
}
```
## Temlplates
```
$tenantid = "TENANTID THIS WILL BE A GUID"
$clientid = "GUID OF CLIENT" 
$clientsecret = "SECRET"
$mycred = New-Object System.Management.Automation.PSCredential($clientid,(ConvertTo-SecureString $clientsecret -AsPlainText -Force))
Connect-AzAccount -Credential $mycred -Tenant $tenantid -ServicePrincipal -SubscriptionName "SUBNAMEHERE"
```


## Plan
Build a snaffler-like tool for crawling storage accounts and using storage explorer to see what can be found

Extract the various powershell scripts used for pulling info via AzureRT, PowerZure & MicroBurst and build a tool for quick wins, similar to AutoPwn

