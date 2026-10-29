
########################################################################
# HelloID-Conn-Prov-Source-NMBRS-Persons
########################################################################

# Initialize default value's
$config = $Configuration | ConvertFrom-Json

#region functions
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

function Get-CompanyList {
    [CmdletBinding()]
    param ()

    [hashtable]$companyList = @{}
    $Headers = @{
        'Authorization'      = "$($apiToken.token_type) $($apiToken.access_token)"
        'X-Subscription-Key' = "$($config.subscriptionKey)"
    }

    $pageSize = 50
    [int] $pageNumber = 1
    $uri = "$($config.BaseUrl)/companies?pageNumber=$pageNumber&pageSize=$pageSize"

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
        foreach ($CompanyInfoItem in $Response.data) {
            $companyList.add($CompanyInfoItem.name, $CompanyInfoItem)
        } 
        $uri = $Response.pagination.NextPage
        $pageNumber++                
    } while ($pageNumber -le $Response.pagination.TotalPages -and [string]::IsNullOrEmpty($uri) -eq $false )  
    Write-Output $companyList 
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
function Get-ManagerEmailDepartmentsList {
    
    $DebtorList = Get-DebtorList
    [hashtable]$ManagerEmailDepartmentsList = @{}
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
                foreach ($manager in $department.Managers) {
                    if (-not [string]::IsNullOrEmpty($manager.Email)) {
                        if (-not $ManagerEmailDepartmentsList.ContainsKey($manager.Email)) {
                            $ManagerEmailDepartmentsList.add($manager.Email, @() )
                        }
                        $ManagerEmailDepartmentsList[$manager.Email] += $department                                                                          
                    }
                }               
            }
            $uri = $departmentListResponse.pagination.NextPage
            $pageNumber++   
                     
        } while ($pageNumber -le $departmentListResponse.pagination.TotalPages -and [string]::IsNullOrEmpty($uri) -eq $false) 
    }
    return $ManagerEmailDepartmentsList
}
function Get-CompanyCurrentPeriod {
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId
    )

    $Headers = @{
        'Authorization'      = "$($apiToken.token_type) $($apiToken.access_token)"
        'X-Subscription-Key' = "$($config.subscriptionKey)"
    }
    $uri = "$($config.BaseUrl)/companies/$CompanyId/period"
    $splatParams = @{
        Uri     = $uri
        Method  = 'GET'
        Headers = $Headers
    }
    if (-not  [string]::IsNullOrEmpty($config.ProxyAddress)) {
        $splatParams['Proxy'] = $config.ProxyAddress
    }
    $Response = Invoke-RestMethod @splatParams 
    if (-not $Response.pagination.TotalRecords -eq 1) {
        throw "Expected exactly one period record for CompanyID $CompanyId, but found $($Response.pagination.TotalRecords)"
    }
    $CurrentPeriod = $Response.data[0]    
    return $CurrentPeriod  
}

function Get-EmployeeListbyCompany {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId,

        [Parameter(Mandatory)]
        [string]
        $EmployeeType
    )

    [hashtable]$employeeList = @{}
    [hashtable]$employeeEmailLookupList = @{}
    $Headers = @{
        'Authorization'      = "$($apiToken.token_type) $($apiToken.access_token)"
        'X-Subscription-Key' = "$($config.subscriptionKey)"
    }
    $pageSize = 50
    [int] $pageNumber = 1
    $uri = "$($config.BaseUrl)/companies/$CompanyId/employees?employeeType=$EmployeeType&pageNumber=$pageNumber&pageSize=$pageSize"
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
        foreach ($PersonalInfoItem in $Response.data) {
            $tmpEmployee = Get-Employee -EmployeeID $PersonalInfoItem.EmployeeID
            $employeeList.add($PersonalInfoItem.EmployeeID, $tmpEmployee)
            if (-not [string]::IsNullOrEmpty($tmpEmployee.PersonalInfo.ContactInfo.businessEmail)) {
                $employeeEmailLookupList.add($tmpEmployee.PersonalInfo.ContactInfo.businessEmail , $PersonalInfoItem.EmployeeID)
            }
        } 
        $uri = $Response.pagination.NextPage
        $pageNumber++                
    } while ($pageNumber -le $Response.pagination.TotalPages -and [string]::IsNullOrEmpty($uri) -eq $false)   
     
    Write-Output $employeeList, $employeeEmailLookupList

}
function Get-EmployeeEmploymentsbyCompany {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId
    )
    
    [hashtable]$employmentList = @{}
    $Headers = @{
        'Authorization'      = "$($apiToken.token_type) $($apiToken.access_token)"
        'X-Subscription-Key' = "$($config.subscriptionKey)"
    }
    $pageSize = 50
    [int] $pageNumber = 1
    $uri = "$($config.BaseUrl)/companies/$CompanyId/employees/employments?pageNumber=$pageNumber&pageSize=$pageSize"
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
        foreach ($EmploymentItem in $Response.data) {
            $employmentList.add($EmploymentItem.EmployeeID, $EmploymentItem)
        } 
        $uri = $Response.pagination.NextPage
        $pageNumber++                
    } while ($pageNumber -le $Response.pagination.TotalPages -and [string]::IsNullOrEmpty($uri) -eq $false)   
     
    Write-Output $employmentList
}

function Get-EmployeeCostCentersByCompany {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId
    )

    [hashtable]$costCenterList = @{}
    $Headers = @{
        'Authorization'      = "$($apiToken.token_type) $($apiToken.access_token)"
        'X-Subscription-Key' = "$($config.subscriptionKey)"
    }
    $pageSize = 50
    [int] $pageNumber = 1
    $uri = "$($config.BaseUrl)/companies/$CompanyId/employees/costcenters?pageNumber=$pageNumber&pageSize=$pageSize"
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
        foreach ($CostCenterItem in $Response.data) {
            $costCenterList.add($CostCenterItem.EmployeeID, $CostCenterItem)
        } 
        $uri = $Response.pagination.NextPage
        $pageNumber++                
    } while ($pageNumber -le $Response.pagination.TotalPages -and [string]::IsNullOrEmpty($uri) -eq $false  )   
     
    Write-Output $costCenterList
}

function Get-Employee {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $EmployeeID
    )
   
    $Headers = @{
        'Authorization'      = "$($apiToken.token_type) $($apiToken.access_token)"
        'X-Subscription-Key' = "$($config.subscriptionKey)"
    }
    $uri = "$($config.BaseUrl)/employees/$EmployeeID"
    $splatParams = @{
        Uri     = $uri
        Method  = 'GET'
        Headers = $Headers
    }

    if (-not  [string]::IsNullOrEmpty($config.ProxyAddress)) {
        $splatParams['Proxy'] = $config.ProxyAddress
    }
    $Response = Invoke-RestMethod @splatParams 
    if (-not ($Response.pagination.TotalRecords -eq 1)) {
        throw "Expected exactly one record for EmployeeID $EmployeeID, but found $($Response.pagination.TotalRecords)"
    }
    $employeeDetails = $Response.data[0]    
    Write-Output $employeeDetails
}

#endregion functions

try {
    Write-Information 'Retrieving NMBRS employee data'
    Start-Sleep -Seconds 30       # Wait for 30 seconds before retrieving the auth token, to ensure any previous token requests by the departments script have been processed
    $apiToken = Get-AuthToken    
    
    if ([string]::IsNullOrEmpty($config.CompanyName)) {  
        throw "CompanyName configuration is missing or empty"
    }
    if ([string]::IsNullOrEmpty($config.DebtorName)) {  
        throw "DebtorName configuration is missing or empty"
    }
         
    # Retrieve list of all departments managed by managers identified by their email address for each debtor  
        
    $ManagerEmailDepartmentsList = Get-ManagerEmailDepartmentsList      

    $CompanyList = Get-CompanyList 
    foreach ($companyName in $config.CompanyName.Split(',')) {
        
        ## Retrieve all the global lists
        [hashtable]$EmployeeList = @{}
        #Lookup all employeetypes
        $employeeType = "applicant,newHire,payroll,formerPayroll,external,formerExternal,rejectedApplicant"
        Write-Information "Retrieving Company list"
        $companyId = $CompanyList[$companyName].companyID
        $debtorId = $CompanyList[$companyName].debtorID

        if ($null -eq $companyId) {
            throw "Company $companyName not found in the list of companies in NMBRS"
        }

        $companyCurrentPeriod = Get-CompanyCurrentPeriod -CompanyId $companyId
     
        #employments

        $EmploymentList = Get-EmployeeEmploymentsByCompany -CompanyId $companyId
        $EmployeeCostCenterList = Get-EmployeeCostCentersByCompany -CompanyId $companyId        

        Write-information "Retrieving Employeelist for each type of employee"
        #Find all employees of each type

        $EmployeeList, $EmployeelookupList = Get-EmployeeListbyCompany -CompanyID $companyId -EmployeeType $employeeType        
        
        foreach ($Employeekey in $EmployeeList.keys) {
          
            $tmpEmployee = $EmployeeList[$Employeekey]           

            $Contracts = [System.Collections.Generic.List[Object]]::new()


            $currentFunction = @{
                Code        = $tmpEmployee.function.code
                Description = $tmpEmployee.function.description
                ID          = $tmpEmployee.function.functionId

            }
            $currentDepartment = @{
                Code        = $tmpEmployee.department.code
                ID          = $tmpEmployee.department.departmentId
                Description = $tmpEmployee.department.description
            }
            # The managerID and number of the manager are generally not the same as the employeeID and employeeNumber of that manager
            # so we need to separately retrieve the manager's employee ID and number from the employee list
            $ManagerEmployeeID = ""
            $ManagerEmployeeNumber = ""
            if (-not [string]::IsNullOrEmpty($tmpEmployee.manager.email)) {
                $ManagerEmployeeID = $EmployeelookupList[$tmpEmployee.manager.email]                                
                if ($null -ne $ManagerEmployeeID) {
                    $ManagerEmployee = $EmployeeList[$ManagerEmployeeID]
                    if ($null -ne $ManagerEmployee) {
                        $ManagerEmployeeNumber = $ManagerEmployee.PersonalInfo.basicInfo.employeeNumber 
                    }
                }
            }            
        
            $currentManager = @{
                Department     = $tmpEmployee.manager.department
                Email          = $tmpEmployee.manager.email
                FirstName      = $tmpEmployee.manager.firstName
                Name           = $tmpEmployee.manager.lastName
                Number         = $tmpEmployee.manager.number
                ID             = $tmpEmployee.manager.managerID
                EmployeeNumber = $companyId + "_" + $ManagerEmployeeNumber
                EmployeeID     = $ManagerEmployeeID 

            }
            if ([string]::IsNullOrEmpty($ManagerEmployeeNumber)) {
                $currentManager.EmployeeNumber = ""
            }

            # Retrieve the current cost centers for the employee based on the current period and the latest creation date
            # select the cost center with the highest percentage among the current period's cost centers

            $CostCentersOfCurrentEmployee = $EmployeeCostCenterList[$Employeekey]
            $CurrentCostcenter = $null
            [hashtable]$tmpCurrentCostCenterList = @{}            
            foreach ($CC in $CostCentersOfCurrentEmployee.employeeCostCenters) {
                if ($CC.period.year -ne $companyCurrentPeriod.period.year -or $CC.period.period -ne $companyCurrentPeriod.period.period) {
                    continue
                }
                if ( $null -eq $tmpCurrentCostCenterList[$CC.costcenters.costcenterId]) {
                    $tmpCurrentCostCenterList.add($CC.costcenters.costcenterId, $CC)
                }
                else {
                    if ($tmpCurrentCostCenterList[$CC.costcenters.costcenterId].createdAt -lt $CC.createdAt) {
                        $tmpCurrentCostCenterList[$CC.costcenters.costcenterId] = $CC
                    }
                }              
            }

            foreach ($Costcenterkey in $tmpCurrentCostCenterList.Keys) {
                if ($null -eq $CurrentCostcenter -or $tmpCurrentCostCenterList[$Costcenterkey].percentage -gt $CurrentCostcenter.percentage) {
                    $CurrentCostcenter = $tmpCurrentCostCenterList[$Costcenterkey ]
                }
            }                 

            $tmpCostCenter = @{
                Code        = $CurrentCostcenter.costcenters.code
                Description = $CurrentCostcenter.costcenters.description
                Id          = $CurrentCostcenter.costcenters.costcenterId
            }
            $tmpCostUnit = @{    
                Code        = $CurrentCostcenter.costUnits.code
                Description = $CurrentCostcenter.costUnits.description
                Id          = $CurrentCostcenter.costUnits.costUnitId
            }

            $currentEmployeeCostCenter = @{
                CostCenter  = $tmpCostCenter
                Kostensoort = $tmpCostUnit
                ID          = $CurrentCostcenter.costcenters.costcenterId
                Percentage  = $CurrentCostcenter.percentage
                default     = $CurrentCostcenter.default
            }           

            #employments

            $employeeEmployments = $EmploymentList[$Employeekey]
            if ($null -ne $employeeEmployments) {            
                foreach ($employeeEmployment in  $employeeEmployments.employments) {                
                    $curContract = @{
                        ContractType              = "Employment"
                        ExternalId                = "Employment_" + $employeeEmployment.employmentId
                        CreationDate              = $employeeEmployment.creationDate 
                        CurrentDepartment         = $currentDepartment
                        CurrentEmployeeCostcenter = $currentEmployeeCostCenter
                        CurrentFunction           = $currentFunction
                        CurrentManager            = $currentManager
                        EndDate                   = $employeeEmployment.enddate
                        Id                        = $employeeEmployment.employmentId
                        StartDate                 = $employeeEmployment.startDate 
                        seniorityDate             = $employeeEmployment.seniorityDate  
                        CompanyName               = $companyName
                        CompanyId                 = $companyId
                        DebtorId                  = $debtorId
                    }
                    $Contracts.add($curContract)
                }
            }
                    
            # only include contracts of which the end date is not older than the configured threshold
            $Contracts = $Contracts | Where-Object { [string]::IsNullOrEmpty($_.EndDate) -or (Get-Date $_.EndDate) -gt (Get-Date).AddDays(-1 * $config.endDateThreshold) }

            if ($Contracts.Count -gt 0) {
                $curPerson = @{            
              
                    BurgerlijkeStaat       = $tmpEmployee.PersonalInfo.partnerInfo.maritalStatus   # for backwards compatibility
                    Birthday               = $tmpEmployee.PersonalInfo.birthInfo.birthdate
                    Contracts              = @() + $Contracts
                    CountryOfBirthISOCode  = $tmpEmployee.PersonalInfo.birthInfo.birthCountry.codeISO
                    CompanyName            = $companyName
                    CompanyId              = $companyId
                    DebtorId               = $debtorId
                    CreationDate           = $tmpEmployee.PersonalInfo.createdAt
                    EmployeeId             = $Employeekey
                    EmployeeNumber         = $companyId + "_" + $tmpEmployee.PersonalInfo.basicInfo.employeeNumber           
                    EmployeeTypeId         = $tmpEmployee.PersonalInfo.basicInfo.employeeType 
                    EmailPrivate           = $tmpEmployee.PersonalInfo.contactInfo.privateEmail
                    EmailWork              = $tmpEmployee.PersonalInfo.contactInfo.businessEmail
                    FirstName              = $tmpEmployee.PersonalInfo.basicInfo.firstName
                    FirstNameInFull        = $tmpEmployee.PersonalInfo.basicInfo.firstNameInFull
                    Gender                 = $tmpEmployee.PersonalInfo.birthInfo.gender
                    Initials               = $tmpEmployee.PersonalInfo.basicInfo.initials
                    LastName               = $tmpEmployee.PersonalInfo.basicInfo.lastName
                    NaamStelling           = "$($tmpEmployee.PersonalInfo.partnerInfo.ascription.Code)"
                    NickName               = $tmpEmployee.PersonalInfo.basicInfo.firstName   
                    MaritalStatus          = $tmpEmployee.PersonalInfo.basicInfo.maritalStatus
                    NMBRSDisplayName       = "$($tmpEmployee.PersonalInfo.basicInfo.firstName) $($tmpEmployee.PersonalInfo.basicInfo.prefix) $($tmpEmployee.PersonalInfo.basicInfo.lastName)"
                    PartnerLastName        = $tmpEmployee.PersonalInfo.partnerInfo.partnerName
                    PartnerPrefix          = $tmpEmployee.PersonalInfo.partnerInfo.partnerPrefix 
                    Prefix                 = $tmpEmployee.PersonalInfo.basicInfo.prefix  
                    #   StartPeriod        = ""
                    #   StartYear         =  ""                        
                    TelephoneMobilePrivate = $tmpEmployee.PersonalInfo.contactInfo.privateMobilePhone               
                    TelephoneMobileWork    = $tmpEmployee.PersonalInfo.contactInfo.businessMobilePhone
                    TelephoneWork          = $tmpEmployee.PersonalInfo.contactInfo.businessPhone
                    Title                  = ""
                    TitleAfter             = ""          
            
                }
                $curPerson | Add-Member -NotePropertyMembers @{ ExternalId = $curPerson.EmployeeID } -Force
                $curPerson | Add-Member -NotePropertyMembers @{ DisplayName = $curPerson.NMBRSDisplayName } -Force
                $ManagerOfId = ""
                $ManagerOfCode = ""
                $ManagerOfName = ""                      
                  
                if (-not [string]::IsNullOrEmpty($curPerson.Emailwork)) {
                    $curdepartments = $ManagerEmailDepartmentsList[$curPerson.Emailwork]    
                    foreach ($department in $curdepartments) { 
                        if ($ManagerOfId -eq "") {
                            $ManagerOfId = "$($department.departmentId)"
                        }
                        else {
                            $ManagerOfId += ",$($department.departmentId)"
                        }
                        if ($ManagerOfCode -eq "") {
                            $ManagerOfCode = "$($department.code)"
                        }
                        else {
                            $ManagerOfCode += ",$($department.code)"
                        }
                        if ($ManagerOfName -eq "") {
                            $ManagerOfName = "$($department.Description)"
                        }
                        else {
                            $ManagerOfName += ",$($department.Description)"
                        }                            
                    }
                }
                                           
            $CurPerson | Add-Member -NotePropertyMembers @{ ManagerOfIds = $ManagerOfId } -Force
            $CurPerson | Add-Member -NotePropertyMembers @{ ManagerOfCodes = $ManagerOfCode } -Force
            $CurPerson | Add-Member -NotePropertyMembers @{ ManagerOfNames = $ManagerOfName } -Force
            Write-Output $CurPerson | ConvertTo-Json -Depth 10           
            }
        }
    }          
  
}
catch {
    $ex = $PSItem
    Write-Information "Could not retrieve NMBRS employees. Error: $($ex.Exception.Message)"
    Write-Information "Could not retrieve NMBRS employees. ErrorDetails: $($ex.ErrorDetails)"
    throw ($ex)
}