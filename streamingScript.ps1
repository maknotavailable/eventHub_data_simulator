# Create a SAS-Token for Azure, using provided credentials
function Get-AzureEHSASToken {
    <# 
 .DESCRIPTION 
 Compute a valid SAS-token for accessing an Azure Event Hub / Service Bus 
 .PARAMETER URI 
 URI of the Azure Event Hub without https:// (<name space>.servicebus.windows.net/<event hub name>) 
 .PARAMETER AccessPolicyName 
 Name of the access policy (Event Hub - Configure - Shared access policies) 
 .PARAMETER AccessPolicyKey 
 Key for the access policy (Event Hub - Configure - Shared access policies) 
 .PARAMETER TokenTimeOut 
 Timeout in seconds for the SAS-token (default 1800 seconds) 
 .EXAMPLE 
    Get-AzureEHSASToken -URI "sepagolabs-eventhub.servicebus.windows.net/workplaceclients" -AccessPolicyName "ReceivePolicy" -AccessPolicyKey "OmT7XZxxxTdIWYblKZ5ReJ/xxxxxxxxxxxxxxxxxw8=" 
 .NOTES 
    Author: Marcel Meurer, marcel.meurer@sepago.de, Twitter: MarcelMeurer 
 #>
    PARAM(
        [Parameter(Mandatory = $True)]
        [string]$URI,
        [Parameter(Mandatory = $True)]
        [string]$AccessPolicyName,
        [Parameter(Mandatory = $True)]
        [string]$AccessPolicyKey,
        [int]$TokenTimeOut = 1800
    )
    [Reflection.Assembly]::LoadWithPartialName("System.Web")| out-null
    $Expires = ([DateTimeOffset]::Now.ToUnixTimeSeconds()) + $TokenTimeOut
    #Building Token
    $SignatureString = [System.Web.HttpUtility]::UrlEncode($URI) + "`n" + [string]$Expires
    $HMAC = New-Object System.Security.Cryptography.HMACSHA256
    $HMAC.key = [Text.Encoding]::ASCII.GetBytes($AccessPolicyKey)
    $Signature = $HMAC.ComputeHash([Text.Encoding]::ASCII.GetBytes($SignatureString))
    $Signature = [Convert]::ToBase64String($Signature)
    $SASToken = "SharedAccessSignature sr=" + [System.Web.HttpUtility]::UrlEncode($URI) + "&sig=" + [System.Web.HttpUtility]::UrlEncode($Signature) + "&se=" + $Expires + "&skn=" + $AccessPolicyName
    return $SASToken
}
# Function written by Marcel Meurer: https://www.powershellgallery.com/packages/Azure.EventHub/0.9.0

# Send piece of data to the Event Hub
function Send-AzureEHDatagram {
    <# 
 .DESCRIPTION 
 Send a datagram to an Azure Event Hub 
 .PARAMETER URI 
 URI of the Azure Event Hub without https:// (<name space>.servicebus.windows.net/<event hub name>) 
 .PARAMETER SASToken 
 A valid SAS authorization token (see Get-AzureEHSASToken) 
 .PARAMETER Datagram 
 Datagram send to the Event Hub in json format. E.g.: { "DeviceId":"cl0e2994872-WestUS", "LogonTime":"34.1"} 
 .PARAMETER TimeOut 
 Timeout for this post (default 60 seconds) 
 .PARAMETER APIVersion 
 API-version string. Default: 2014-01 
 .EXAMPLE 
    Send-AzureEHDatagram -URI "sepagolabs-eventhub.servicebus.windows.net/workplaceclients" -SASToken $SASToken -Datagram '{ "DeviceId":"cl0e2994872-WestUS", "LogonTime":"34.1"}' 
 .NOTES 
    Author: Marcel Meurer, marcel.meurer@sepago.de, Twitter: MarcelMeurer 
 #>
    PARAM(
        [Parameter(Mandatory = $True)]
        [string]$URI,
        [Parameter(Mandatory = $True)]
        [string]$SASToken,
        [Parameter(Mandatory = $True)]
        [string]$Datagram,
        [int]$TimeOut = 60,
        [string]$APIVersion = "2014-01"
    )
    try {
        $webRequest = Invoke-WebRequest -Method POST -Uri ("https://" + $URI + "/messages?timeout=" + $TimeOut + "&api-version=" + $APIVersion) -Header @{ Authorization = $SASToken} -ContentType "application/atom+xml;type=entry;charset=utf-8" -Body $Datagram -ErrorAction SilentlyContinue
    } 
    catch {
        write-error("Cannot access the api. Webrequest return code is: " + $_.Exception.Response.StatusCode + "`n" + $_.Exception.Response.StatusDescription)
        break
    }
    return $webRequest
}
# Function written by Marcel Meurer: https://www.powershellgallery.com/packages/Azure.EventHub/0.9.0

## EVENT HUB ACCOUNT DETAILS
$URI = "<service bus>.servicebus.windows.net/<event hub name>"
$SASToken = Get-AzureEHSASToken -URI $URI -AccessPolicyName "<policy name>" -AccessPolicyKey "<access key>"

## LOAD DATA FILE
$csv = Get-Content -path 'C:\Users\<path to file>\<filename>.csv' 
$payload = ConvertFrom-Csv -Delimiter ',' -InputObject $csv 

## FIRE DATA AT EVENT HUB, one row at a times
# Optional: Loop to loop through entire data file; 10 loops
#For ($i = 0; $i -lt 10; $i++) { 
    # Loop through each row, one at a time. Can be adjusted for batch processing
    foreach ($row in $payload) {
        # Convert data to Event Hub appropriate format (JSON)
        $rowjson = ConvertTo-Json $row

        # Web request sending data package
        Send-AzureEHDatagram -URI $URI -SASToken $SASToken -Datagram $rowjson
        
        # Custom Delay Timer
        start-sleep -seconds 1
    }
#}


