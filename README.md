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

## Regexes for Searching Through Files
```

description = "Azure Service Principal Client Secret"
regex = '''(?i)(secret|key|password)\s*:?=?\s*['\"][0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}['\"]'''
[[rules]]
description = "Azure DevOps Personal Access Token"
regex = '''(?i)(pat|token)\s*:?=?\s*['\"]([a-z0-9]{52})['\"]'''
[[rules]]
description = "Azure Account Key"
regex = '''(?i)(secret|key)\s*:?=?\s*['\"]([a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]{88})['\"]'''
tags = ["Azure Storage Account", "Azure Cosmos DB"]
[[rules]]
description = "Azure Storage Connection String"
regex = '''DefaultEndpointsProtocol=https;AccountName=[a-z0-9]{3,24};AccountKey=[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]{88};EndpointSuffix=.+'''
[[rules]]
description = "Azure Cosmos DB Connection String"
regex = '''AccountEndpoint=https:\/\/.+:443\/;AccountKey=[a-zA-Z0-9!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]{88};'''
[[rules]]
description = "Generic Secret"
regex = '''(?i)secret\s*:?=?\s*['\"][0-9a-zA-Z-_/]{8,40}['\"]'''
# rules from trufflehog
[[rules]]
description = "Amazon MWS Auth Token"
regex = '''amzn\\.mws\\.[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'''
[[rules]]
description = "AWS AppSync GraphQL Key"
regex = '''da2-[a-z0-9]{26}'''
[[rules]]
description = "Google OAuth"
regex = '''[0-9]+-[0-9A-Za-z_]{32}\\.apps\\.googleusercontent\\.com'''
tags = ["Cloud Platform", "Drive", "Gmail", "YouTube"]
[[rules]]
description = "Google API Key"
regex = '''AIza[0-9A-Za-z\\-_]{35}'''
tags = ["Cloud Platform", "Drive", "Gmail", "YouTube"]
[[rules]]
description = "Google OAuth Access Token"
regex = '''ya29\\.[0-9A-Za-z\\-_]+'''
[[rules]]
description = "MailChimp API Key"
regex = '''[0-9a-f]{32}-us[0-9]{1,2}'''
[[rules]]
description = "Mailgun API Key"
regex = '''key-[0-9a-zA-Z]{32}'''
[[rules]]
description = "Square Access Token"
regex = '''sq0atp-[0-9A-Za-z\\-_]{22}'''
[[rules]]
description = "Square OAuth Secret"
regex = '''sq0csp-[0-9A-Za-z\\-_]{43}'''
[[rules]]
description = "Telegram Bot API Key"
regex = '''[0-9]+:AA[0-9A-Za-z\\-_]{33}'''
```

## Templates
Template for connecting with clientID and information
```
$tenantid = "<INSET TENANT ID>"
$clientid = "<INSERT CLIENT ID/USERNAME>"
$clientsecret = "<INSERT CLIENT SECRET/PASSWORD"
$subscription = "<INSERT SUBCRIPTION>"
$mycred = New-Object System.Management.Automation.PSCredential($clientid,(ConvertTo-SecureString $clientsecret -AsPlainText -Force))
Connect-AzAccount -Credential $mycred -Tenant $tenantid -ServicePrincipal -Subscription $subscription
# Below is if you need to also authenticate to Az as well
az login --service-principal -u $clientid -p $clientsecret --tenant $tenantid
```


## Plan
Build a snaffler-like tool for crawling storage accounts and using storage explorer to see what can be found

Extract the various powershell scripts used for pulling info via AzureRT, PowerZure & MicroBurst and build a tool for quick wins, similar to AutoPwn

