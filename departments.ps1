########################################################################
# HelloID-Conn-Prov-Source-NMBRS-Departments
########################################################################
# Initialize default value's
$config = $Configuration | ConvertFrom-Json

function Get-AuthToken {
    [CmdletBinding()]
    param ()  

    $refreshToken = $null

    if ([System.IO.File]::Exists($config.RefreshTokenSaveFile)) {
        $savedRefreshToken = Get-Content -Path $config.RefreshTokenSaveFile -Raw
        try {
            $secureRefreshToken = ConvertTo-SecureString -String $savedRefreshToken
            $refreshToken = (New-Object System.Net.NetworkCredential('', $secureRefreshToken)).Password
        }
        catch {            
            throw 'The saved refresh token could not be decrypted. Run this script under the Windows account that saved it, or remove the file and provide a new refresh token.'
            
        }
    }
    if ([string]::IsNullOrEmpty($refreshToken)) {    
        $refreshToken = $config.RefreshToken 
    }

    $headers = @{
        'content-type'  = 'application/x-www-form-urlencoded'
        'Authorization' = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("$($config.Client_id):$($config.Client_secret)"))
        'host'          = "$($config.Tokenhost)"
    }
    $body = "refresh_token=$($refreshToken)&grant_type=refresh_token"
    $splatApitoken = @{
        Uri     = $Config.TokenUrl
        Method  = 'POST'
        Body    = $body
        Headers = $headers
    }

    if (-not  [string]::IsNullOrEmpty($config.ProxyAddress)) {
        $splatApitoken['Proxy'] = $config.ProxyAddress
    }
    try {
        $result = Invoke-RestMethod @splatApitoken        
        $secureRefreshToken = ConvertTo-SecureString -String $result.refresh_token -AsPlainText -Force
        ConvertFrom-SecureString -SecureString $secureRefreshToken | Set-Content -Path $config.RefreshTokenSaveFile -Encoding ASCII -NoNewline      
        return $result
    }
    catch {
        throw $_
    }
}

function Get-DebtorList {
    [CmdletBinding()]
    param ()

    [hashtable]$debtorList = @{}
    $Headers = @{
        'Authorization'      = "$($apiToken.token_type) $($apiToken.access_token)"
        'X-Subscription-Key' = "$($config.subscriptionKey)"
    }

    $pageSize = 50
    [int] $pageNumber = 1
    $uri = "$($config.BaseUrl)/debtors?pageNumber=$pageNumber&pageSize=$pageSize"

    do {    
        $splatParams = @{
            Uri     = $uri
            Method  = 'GET'
            Headers = $Headers
        }

        if (-not  [string]::IsNullOrEmpty($config.ProxyAddress)) {
            $splatParams['Proxy'] = $config.ProxyAddress
        }
        $Response = Invoke-RestMethod @splatParams 
        if ($Response.pagination.TotalPages -gt 10000) {
            Write-Information "Total pages is greater than 10000, stopping to avoid infinite loop"
            throw  "Total pages is greater than 10000, stopping to avoid infinite loop"
        }
        foreach ($debtor in $Response.data) {
            $debtorList.add($debtor.name, $debtor.debtorID)
        } 
        $uri = $Response.pagination.NextPage
        $pageNumber++                
    } while ($pageNumber -le $Response.pagination.TotalPages -and [string]::IsNullOrEmpty($uri) -eq $false)  
    Write-Output $debtorList 
}
#region functions

#endregion

try {
    Write-Information 'Retrieving NMBRS Department data'
  
    $apiToken = Get-AuthToken 
   

    if ([string]::IsNullOrEmpty($config.DebtorName)) {  
        throw "DebtorName configuration is missing or empty"
    }
    
    $DebtorList = Get-DebtorList
    foreach ($debtorName in $config.DebtorName.Split(',')) {
        $debtorId = $DebtorList[$debtorName]

        if ($null -eq $debtorId) {
            throw "Debtor $debtorName not found in the list of debtors"
        }
  
        $Headers = @{
            'Authorization'      = "$($apiToken.token_type) $($apiToken.access_token)"
            'X-Subscription-Key' = "$($config.subscriptionKey)"
        }

        $pageSize = 50
        [int] $pageNumber = 1
        $uri = "$($config.BaseUrl)/debtors/$debtorId/departments?pageNumber=$pageNumber&pageSize=$pageSize"   
        do {    
            $splatdepartmentList = @{
                Uri     = $uri
                Method  = 'GET'
                Headers = $Headers
            }
            if (-not  [string]::IsNullOrEmpty($config.ProxyAddress)) {
                $splatdepartmentList['Proxy'] = $config.ProxyAddress
            }


            $departmentListResponse = Invoke-RestMethod @splatdepartmentList 
            if ($departmentListResponse.pagination.TotalPages -gt 10000) {
                Write-Information "Total pages is greater than 10000, stopping to avoid infinite loop"
                throw  "Total pages is greater than 10000, stopping to avoid infinite loop"
            }
            foreach ($department in $departmentListResponse.Data) {

                $ManagerIds = ""
                $ManagerEmails = ""
                if ($null -ne $department.Managers) {
                    $ManagerIds = ($department.Managers | ForEach-Object { $_.ManagerId }) -join ','
                    $ManagerEmails = ($department.Managers | ForEach-Object { $_.Email }) -join ','
                }

                $curDepartment = @{
                    DepartmentId = $department.departmentId
                    ExternalId  = $department.Code
                    DisplayName = $department.Description
                    ManagerIds = $ManagerIds
                    DebtorId = $debtorId
                    DebtorName = $debtorName
                    ManagerEmails = $ManagerEmails
                }
                Write-Output $curDepartment | ConvertTo-Json -Depth 10
            }
            $uri = $departmentListResponse.pagination.NextPage
            $pageNumber++   
                     
        } while ($pageNumber -le $departmentListResponse.pagination.TotalPages -and [string]::IsNullOrEmpty($uri) -eq $false) 
    }
}
catch {
    $ex = $PSItem
    Write-Information "Could not retrieve NMBRS departments. Error: $($ex.Exception.Message)"
    Write-Information "Could not retrieve NMBRS departments. ErrorDetails: $($ex.ErrorDetails)"
}