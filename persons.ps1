########################################################################
# HelloID-Conn-Prov-Source-NMBRS-Persons
#
# Version: 1.1.0
########################################################################
# Initialize default value's
$config = $Configuration | ConvertFrom-Json

# Set debug logging
switch ($($config.IsDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}

#region functions
function Invoke-NMBRSRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Uri,

        [Parameter(Mandatory)]
        [string]
        $Service,

        [Parameter(Mandatory)]
        [string]
        $SoapBody
    )

    switch ($service){
        'EmployeeService'{
            $soapHeader = "
            <emp:AuthHeaderWithDomain>
                <emp:Username>$($config.UserName)</emp:Username>
                <emp:Token>$($config.Token)</emp:Token>
                <emp:Domain>$($config.Domain)</emp:Domain>
            </emp:AuthHeaderWithDomain>"

        }
    }

    $xmlRequest = "<?xml version=`"1.0`" encoding=`"utf-8`"?>
        <soap:Envelope xmlns:soap= `"http://www.w3.org/2003/05/soap-envelope`" xmlns:emp=`"https://api.nmbrs.nl/soap/$($config.version)/$service`">
        <soap:Header>
            $soapHeader
        </soap:Header>
        <soap:Body>
            $soapBody
        </soap:Body>
        </soap:Envelope>"

    try {
        $splatParams = @{
            Uri         = $Uri
            Method      = 'POST'
            Body        = $xmlRequest
            ContentType = 'text/xml; charset=utf-8'
        }

        if (-not  [string]::IsNullOrEmpty($config.ProxyAddress)) {
            $splatParams['Proxy'] = $config.ProxyAddress

        }
        #Invoke-WebRequest @splatParams
        Invoke-RestMethod @splatParams -Verbose:$false
    }
    catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

function Find-PersonIdByEmail {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]
        $PersonalInformation,

        [Parameter(Mandatory)]
        [string]
        $LookupEmail
    )

    $ResultEmployeeID = $null
    $ResultEmployeeNumber = $null

    foreach ($key in $personalInformationList.keys) {
        $NMBRS_Employee = $personalInformationList[$key]
        $curEmployeeId = $NMBRS_Employee.EmployeeId
        $curInfo = $null
        foreach ($info in $NMBRS_Employee.EmployeePersonalInfos.ChildNodes) {
            if (($null -eq $Curinfo) -or ($curInfo.CreationDate -lt $info.CreationDate)) {
                $curInfo = $info
            }
        }
        if ($curInfo.EmailWork -eq $LookupEmail) {
            $ResultEmployeeID = $curEmployeeId
            $ResultEmployeeNumber = $curInfo.EmployeeNumber
            break
        }
    }
    return  $ResultEmployeeID, $ResultEmployeeNumber
}

function Find-PersonIdByName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [hashtable]
        $PersonalInformation,

        [string]
        $FirstName,

        [string]
        $LastName
    )

    $ResultEmployeeID = $null
    $ResultEmployeeNumber = $null

    foreach ($key in $personalInformationList.keys) {
        $NMBRS_Employee = $personalInformationList[$key]
        $curEmployeeId = $NMBRS_Employee.EmployeeId
        $curInfo = $null
        foreach ($info in $NMBRS_Employee.EmployeePersonalInfos.ChildNodes) {
            if (($null -eq $Curinfo) -or ($curInfo.CreationDate -lt $info.CreationDate)) {
                $curInfo = $info
            }
        }
        if ( (($curInfo.FirstName -eq $FirstName) -or ($curInfo.NickName -eq $FirstName)) -and ($curInfo.LastName -eq $LastName)) {
            $ResultEmployeeID = $curEmployeeId
            $ResultEmployeeNumber = $curInfo.EmployeeNumber
            break
        }
    }
    return  $ResultEmployeeID, $ResultEmployeeNumber
}

function Get-CurrentDepartment {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $EmployeeId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:Department_GetCurrent xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:EmployeeId>$EmployeeId</emp:EmployeeId>
            </emp:Department_GetCurrent>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Department_GetCurrentResponse.Department_GetCurrentResult
}


function Get-CurrentContracts{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $EmployeeId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:Contract_GetCurrentPeriod xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:EmployeeId>$EmployeeId</emp:EmployeeId>
            </emp:Contract_GetCurrentPeriod>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Contract_GetCurrentResponse.Contract_GetCurrentResult.EmployeeContractItem
}


function Get-CurrentCostCenter{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $EmployeeId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:CostCenter_GetCurrent xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:EmployeeId>$EmployeeId</emp:EmployeeId>
            </emp:CostCenter_GetCurrent>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.CostCenter_GetCurrentResponse.CostCenter_GetCurrentResult.EmployeeCostcenter

}

function Get-CurrentFunction{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $EmployeeId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:Function_GetCurrent xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:EmployeeId>$EmployeeId</emp:EmployeeId>
            </emp:Function_GetCurrent>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Function_GetCurrentResponse.Function_GetCurrentResult
}

function Get-CurrentManager{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $EmployeeId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:Manager_GetCurrent xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:EmployeeId>$EmployeeId</emp:EmployeeId>
            </emp:Manager_GetCurrent>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Manager_GetCurrentResponse.Manager_GetCurrentResult
}

function Get-CurrentPersonalInfo{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $EmployeeId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:PersonalInfo_GetCurrent xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:EmployeeId>$EmployeeId</emp:EmployeeId>
            </emp:PersonalInfo_GetCurrent>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Manager_GetCurrentResponse.Manager_GetCurrentResult
}

function Get-EmployeeContractsbyCompany {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:Contract_GetAll_AllEmployeesByCompany xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:CompanyID>$CompanyId</emp:CompanyID>
            </emp:Contract_GetAll_AllEmployeesByCompany>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Contract_GetAll_AllEmployeesByCompanyResponse.Contract_GetAll_AllEmployeesByCompanyResult.EmployeeContractItemGlobal
}

function Get-EmployeeDepartmentsbyCompany {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:Department_GetAll_AllEmployeesByCompany xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:CompanyID>$CompanyId</emp:CompanyID>
            </emp:Department_GetAll_AllEmployeesByCompany>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Department_GetAll_AllEmployeesByCompanyResponse.Department_GetAll_AllEmployeesByCompanyResult.EmployeeDepartmentItem
}

function Get-EmployeeEmploymentsbyCompany {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:Employment_GetAll_AllEmployeesByCompany xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:CompanyID>$CompanyId</emp:CompanyID>
            </emp:Employment_GetAll_AllEmployeesByCompany>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Employment_GetAll_AllEmployeesByCompanyResponse.Employment_GetAll_AllEmployeesByCompanyResult.EmployeeEmploymentItem
}

function Get-EmployeeFunctionsbyCompany {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:Function_GetAll_AllEmployeesByCompany_V2 xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:CompanyID>$CompanyId</emp:CompanyID>
            </emp:Function_GetAll_AllEmployeesByCompany_V2>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Function_GetAll_AllEmployeesByCompany_V2Response.Function_GetAll_AllEmployeesByCompany_V2Result.EmployeeFunctionItem_V2
}

function Get-EmployeeListbyCompany{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId,

        [Parameter(Mandatory)]
        [string]
        $EmployeeTypeId
    )

    $employeesofType = [System.Collections.Generic.List[Object]]::new()


    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:List_GetByCompany >
                <emp:CompanyId>$CompanyId</emp:CompanyId>
                <emp:EmployeeType>$EmployeeTypeId</emp:EmployeeType>
            </emp:List_GetByCompany>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.List_GetByCompanyResponse.List_GetByCompanyResult.Employee

}
function Get-EmployeeSchedulesbyCompany {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $CompanyId
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:Schedule_GetAll_AllEmployeesByCompany xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:CompanyID>$CompanyId</emp:CompanyID>
            </emp:Schedule_GetAll_AllEmployeesByCompany>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Schedule_GetAll_AllEmployeesByCompanyResponse.Schedule_GetAll_AllEmployeesByCompanyResult.EmployeeScheduleItem
}

function Get-EmployeeTypes {
    param ()

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:EmployeeType_GetList xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            </emp:EmployeeType_GetList>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.EmployeeType_GetListResponse.EmployeeType_GetListResult.EmployeeType

}

function Get-PersonalInfoWithoutBSN {
    [CmdletBinding()]
    param ()

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<PersonalInfoWithoutBSN_Get_GetAllEmployeesByCompany xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:CompanyID>$($config.CompanyID)</emp:CompanyID>
            </PersonalInfoWithoutBSN_Get_GetAllEmployeesByCompany>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.PersonalInfoWithoutBSN_Get_GetAllEmployeesByCompanyResponse.PersonalInfoWithoutBSN_Get_GetAllEmployeesByCompanyResult.PersonalInfoItem
}

function Get-PersonalInfo {
    [CmdletBinding()]
    param ()

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<PersonalInfo_GetAll_AllEmployeesByCompany xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:CompanyID>$($config.CompanyID)</emp:CompanyID>
            </PersonalInfo_GetAll_AllEmployeesByCompany>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.PersonalInfo_GetAll_AllEmployeesByCompanyResponse.PersonalInfo_GetAll_AllEmployeesByCompanyResult.PersonalInfoItem
}

#endregion functions

try {
    Write-Verbose 'Retrieving NMBRS employee data'

    $companyId = $config.CompanyId   #current implementation collects persons for a single company

    ## Retrieve all the global lists
    [hashtable]$EmployeeList = @{}
    #Lookup all employeetypes
    $employeeTypeList = Get-EmployeeTypes
    Write-Verbose "Retrieving Employeelist for each type of employee"
    #Find all employees of each type
    foreach ($EmployeeType in $employeeTypeList) {
        $tmpEmployeeList = Get-EmployeeListbyCompany -CompanyID $CompanyId -EmployeeType $EmployeeType.Id
        foreach ($employee in $tmpEmployeeList) {
            $tmpEmployee = @{
                Id                      = $employee.Id
                Number                  = $employee.Number
                DisplayName             = $employee.DisplayName
                EmployeeTypeId          = $EmployeeType.Id
                EmployeeTypeDescription = $EmployeeType.Description
            }
            $EmployeeList.add($tmpEmployee.id, $tmpEmployee)
        }
    }

    # contracts
    Write-Verbose "Retrieving EmployeeContracts of company [$CompanyId]"
    $tmpContractList = Get-EmployeeContractsbyCompany -CompanyId $CompanyId
    [hashtable]$ContractList = @{}
    foreach ($ContractItem in $tmpContractList) {
        $ContractList.add($ContractItem.EmployeeID, $ContractItem)
    }

    # departments
    Write-Verbose "Retrieving departments of company [$CompanyId]"
    $tmpDepartmentList = Get-EmployeeDepartmentsByCompany -CompanyId $CompanyId
    [hashtable]$DepartmentList = @{}
    foreach ($DepartmentItem in $tmpDepartmentList) {
        $DepartmentList.add($DepartmentItem.EmployeeID, $DepartmentItem)
    }

    # functions
    Write-Verbose "Retrieving functions of company [$CompanyId]"
    $tmpFunctionList = Get-EmployeeFunctionsByCompany -CompanyId $CompanyId
    [hashtable]$FunctionList = @{}
    foreach ($FunctionItem in $tmpFunctionList) {
        $FunctionList.add($FunctionItem.EmployeeID, $functionItem)
    }
    #employments
    Write-Verbose "Retrieving employments of company [$CompanyId]"
    $tmpEmploymentList = Get-EmployeeEmploymentsByCompany -CompanyId $CompanyId
    [hashtable]$EmploymentList = @{}
    foreach ($EmploymentItem in $tmpEmploymentList) {
        $EmploymentList.add($EmploymentItem.EmployeeID, $EmploymentItem)
    }
    # schedules
    Write-Verbose "Retrieving schedules of company [$CompanyId]"
    $tmpScheduleList = Get-EmployeeSchedulesByCompany -CompanyId $CompanyId
    [hashtable]$ScheduleList = @{}
    foreach ($ScheduleItem in $tmpScheduleList) {
        $ScheduleList.add($ScheduleItem.EmployeeID, $ScheduleItem)
    }
    # PersonalInformation
    Write-Verbose "Retrieving PersonalInformation list of company [$CompanyId]"
    $tmpPersonalInformationList = Get-PersonalInfoWithoutBSN
    [hashtable]$personalInformationList = @{}
    foreach ($PersonalInfoItem in $tmpPersonalInformationList) {
        $personalInformationList.add($PersonalInfoItem.EmployeeID, $PersonalInfoItem)
    }
    # check on missing data in personalInformationList
    Write-Verbose "Supplementing possible missing person data in PersonalInformation if required"
    foreach ($employeeId in $EmployeeList.keys) {
        if ($null -eq $personalInformationList[$employeeId]) {
            $getInformationResult = Get-CurrentPersonalInfo -EmployeeID $curEmployeeId
            $personalInformationList[$employeeId] = $getInformationResult
        }
    }

    ## Global lists have been collected
    ## main loop to create the persons

    foreach ($key in $personalInformationList.keys) {
        $NMBRS_Employee = $personalInformationList[$key]
        $curEmployeeId = $NMBRS_Employee.EmployeeId

        Write-Verbose "Retrieving NMBRS employee data for EmployeeID [$curEmployeeId]"

        # Find the current personal data record of the Employee
        $curInfo = $null
        foreach ($info in $NMBRS_Employee.EmployeePersonalInfos.ChildNodes) {
            if (($null -eq $Curinfo) -or ($curInfo.CreationDate -lt $info.CreationDate)) {
                $curInfo = $info
            }
        }

        #currentFunction
        $getFunctionResult = Get-CurrentFunction -EmployeeID $curEmployeeId
        $currentFunction = @{
            Code        = $getFunctionResult.Code
            Description = $getFunctionResult.Description
            ID          = $getFunctionResult.Id

        }

        #currentDepartment
        $getDepartmentResult = Get-CurrentDepartment -EmployeeID $curEmployeeId
        $currentDepartment = @{
            Code        = $getDepartmentResult.Code
            ID          = $getDepartmentResult.Id
            Description = $getDepartmentResult.Description
        }

        #currentManager
        $getManagerResult = Get-CurrentManager -EmployeeID $curEmployeeId
        if (-not [string]::IsNullOrEmpty($getManagerResult.Email)) {
            ($managerEmployeeId, $managerEmployeeNumber) = Find-PersonIdByEmail -PersonalInformation $personalInformationList -LookupEmail $getManagerResult.Email
        }
        if ($null -eq $managerEmployeeId) {
            if (-not [string]::IsNullOrEmpty($getManagerResult.Name)) {
            ($managerEmployeeId, $managerEmployeeNumber) = Find-PersonIdByName -PersonalInformation $personalInformationList -FirstName $getManagerResult.FirstName -LastName $getManagerResult.Name
            }
        }
        $currentManager = @{
            Department     = $getManagerResult.Department
            Email          = $getManagerResult.Email
            FirstName      = $getManagerResult.FirstName
            Name           = $getManagerResult.Name
            Number         = $getManagerResult.Number
            EmployeeID     = $managerEmployeeId
            EmployeeNumber = $managerEmployeeNumber
        }

        #currentCostcenter
        $getCostcenterResult = Get-CurrentCostcenter -EmployeeID $curEmployeeId
        $tmpCostCenter = @{
            Code        = $GetCostcenterResult.Costcenter.Code
            Description = $GetCostcenterResult.Costcenter.Description
        }
        $tmpkostensoort = @{
            Code        = $GetCostcenterResult.Kostensoort.Code
            Description = $GetCostcenterResult.Kostensoort.Description
        }
        $currentEmployeeCostCenter = @{
            CostCenter  = $tmpCostCenter
            Kostensoort = $tmpKostensoort
            ID          = $GetCostcenterResult.Id
            Percentage  = $GetCostcenterResult.Percentage
            default     = $GetCostcenterResult.default
        }

        #employeeContracts; if more than one contract with the same Id is found, only the current one is retained
        $employeeContracts = [System.Collections.Generic.List[Object]]::new()
        if ($contractList[$curEmployeeId]) {
            [hashtable] $tmpcontracts = @{}
            foreach ($Contract in $contractList[$curEmployeeId].EmployeeContracts.ChildNodes) {
                if ($null -ne $Contract.ContractId) {
                    if ($null -eq $tmpcontracts[$Contract.ContractId]) {
                        $tmpcontracts[$Contract.ContractId] = $Contract
                    }
                    else {
                        #more than one entry with the same contract id is found. This is not allowed.
                        #so the current stored one is replaced by the "current" one from NMBRS
                        $currentContracts = Get-CurrentContracts -EmployeeID $curEmployeeId
                        foreach ($currentContract in $currentContracts.EmployeeContracts.ChildNodes) {
                            if ($CurrentContract.ContractId -eq $Contract.ContractId) {
                                $tmpcontracts[$Contract.ContractId] = $CurrentContract
                            }
                        }
                    }
                }
            }
            foreach ($ContractId in $tmpContracts.keys) {
                $Contract = $tmpContracts[$ContractId]
                $employeeContracts.add($Contract)
            }
        }

        $employeeDepartments = [System.Collections.Generic.List[Object]]::new()
        if ($DepartmentList[$curEmployeeId]) {
            foreach ($Department in $DepartmentList[$curEmployeeId].EmployeeDepartments.ChildNodes) {
                $employeeDepartments.add($Department)
            }

        }

        $employeeEmployments = [System.Collections.Generic.List[Object]]::new()
        if ($EmploymentList[$curEmployeeId]) {
            foreach ($Employment in $EmploymentList[$curEmployeeId].EmployeeEmployments.ChildNodes) {
                $employeeEmployments.add($Employment)
            }
        }

        $employeeFunctions = [System.Collections.Generic.List[Object]]::new()
        if ($FunctionList[$curEmployeeId]) {
            foreach ($Function in $FunctionList[$curEmployeeId].EmployeeFunctions.ChildNodes) {
                $employeeFunctions.add($Function)
            }
        }

        $employeeSchedules = [System.Collections.Generic.List[Object]]::new()
        if ($ScheduleList[$curEmployeeId]) {
            foreach ($Schedule in $ScheduleList[$curEmployeeId].EmployeeSchedules.ChildNodes) {
                $employeeSchedules.add($Schedule)
            }
        }

        if ($EmployeeList[$curEmployeeId]) {
            $EmployeeTypeId = $EmployeeList[$curEmployeeId].EmployeeTypeId
            $EmployeetypeDescription = $EmployeeList[$curEmployeeId].EmployeeTypeDescription
        }
        else {
            $EmployeeTypeId = $null
            $EmployeetypeDescription = $null
        }

        #personContracts
        $Contracts = [System.Collections.Generic.List[Object]]::new()

        foreach ($employeeContract in  $employeeContracts) {

            $curContract = @{
                ExternalId                = "contract_" + $employeeContract.contractID
                ContractType              = "contract"
                ID                        = $employeeContract.contractID
                CreationDate              = $employeeContract.CreationDate
                CurrentDepartment         = $currentDepartment
                CurrentEmployeeCostcenter = $currentEmployeeCostCenter
                CurrentFunction           = $currentFunction
                CurrentManager            = $currentManager
                EndDate                   = $employeeContract.EndDate
                EmploymentType            = $employeeContract.EmployementType   # typo in api Employement instead of Employment
                EmploymentSequenceTaxId   = $employeeContract.EmploymentSequenceTaxId
                Indefinite                = $employeeContract.Indefinite
                PhaseClassification       = $employeeContract.PhaseClassification
                Startdate                 = $EmployeeContract.Startdate
                TrialPeriod               = $EmployeeContract.TrialPeriod
                WrittenContract           = $employeeContract.WrittenContract
                HoursPerWeek              = $employeeContract.HoursPerWeek
            }
            $Contracts.add($CurContract)
        }

        #Departments
        foreach ($employeeDepartment in  $employeeDepartments) {


            $curContract = @{
                ContractType              = "department"
                ExternalId                = "department_" + $employeeDepartment.Id
                Code                      = $employeeDepartment.Code
                CreationDate              = $employeeDepartment.CreationDate
                CurrentDepartment         = $currentDepartment
                CurrentEmployeeCostcenter = $currentEmployeeCostCenter
                CurrentFunction           = $currentFunction
                CurrentManager            = $currentManager
                Description               = $employeeDepartment.Description
                Id                        = $employeeDepartment.Id
                StartPeriod               = $employeeDepartment.StartPeriod
                StartYear                 = $employeeDepartment.StartYear
            }
            $Contracts.add($CurContract)
        }

        #employments
        foreach ($employeeEmployment in  $employeeEmployments) {

            $curContract = @{
                ContractType              = "Employment"
                ExternalId                = "Employment_" + $employeeEmployment.EmploymentId
                CreationDate              = $employeeEmployment.CreationDate
                CurrentDepartment         = $currentDepartment
                CurrentEmployeeCostcenter = $currentEmployeeCostCenter
                CurrentFunction           = $currentFunction
                CurrentManager            = $currentManager
                EndDate                   = $employeeEmployment.Enddate
                Id                        = $employeeEmployment.EmploymentId
                StartDate                 = $employeeEmployment.StartDate
                InitialStartDate          = $employeeEmployment.InitialStartDate
            }
            $Contracts.add($CurContract)
        }

        #functions
        foreach ($employeeFunction in  $employeeFunctions) {

            $curContract = @{
                ContractType              = "function"
                ExternalId                = "function_" + $employeeFunction.RecordId
                CreationDate              = $employeeFunction.CreationDate
                CurrentDepartment         = $currentDepartment
                CurrentEmployeeCostcenter = $currentEmployeeCostCenter
                CurrentFunction           = $currentFunction
                CurrentManager            = $currentManager
                FunctionCode              = $employeeFunction.Function.Code
                FunctionDescription       = $employeeFunction.Function.Description
                FunctionId                = $employeeFunction.Function.Id
                RecordId                  = $employeeFunction.RecordId
                StartPeriod               = $employeeFunction.StartPeriod
                StartYear                 = $employeeFunction.StartYear
            }
            $Contracts.add($CurContract)
        }

        #Schedules
        foreach ($employeeSchedule in  $employeeSchedules) {

            $curContract = @{
                ContractType              = "Schedule"
                ExternalId                = "Schedule_" + $employeeSchedule.Id
                CreationDate              = $employeeSchedule.CreationDate
                CurrentDepartment         = $currentDepartment
                CurrentEmployeeCostcenter = $currentEmployeeCostCenter
                CurrentFunction           = $currentFunction
                CurrentManager            = $currentManager
                Id                        = $employeeSchedule.Id
                StartDate                 = $employeeSchedule.StartDate
                HoursMonday               = $employeeSchedule.HoursMonday
                HoursTuesday              = $employeeSchedule.HoursTuesday
                HoursWednesday            = $employeeSchedule.HoursWednesday
                HoursThursday             = $employeeSchedule.HoursThursday
                HoursFriday               = $employeeSchedule.HoursFriday
                HoursSaturday             = $employeeSchedule.HoursSaturday
                HoursSunday               = $employeeSchedule.HoursSunday
                HoursMonday2              = $employeeSchedule.HoursMonday2
                HoursTuesday2             = $employeeSchedule.HoursTuesday2
                HoursWednesday2           = $employeeSchedule.HoursWednesday2
                HoursThursday2            = $employeeSchedule.HoursThursday2
                HoursFriday2              = $employeeSchedule.HoursFriday2
                HoursSaturday2            = $employeeSchedule.HoursSaturday2
                HoursSunday2              = $employeeSchedule.HoursSunday2
                ParttimePercentage        = $employeeSchedule.ParttimePercentage
            }
            $Contracts.add($CurContract)
        }
        #Person
        $CurPerson = @{
            BurgerlijkeStaat        = $curInfo.BurgerlijkeStaat
            #Birthday = $curInfo.Birthday
            Contracts               = $Contracts
            CreationDate            = $curInfo.CreationDate
            #CountryOfBirthISOCode =$curInfo.CountryOfBirthISOCode
            EmployeeID              = $curEmployeeId
            EmployeeNumber          = $curInfo.EmployeeNumber
            EmployeeTypeId          = $EmployeeTypeId
            EmployeeTypeDescription = $EmployeeTypeDescription
            EmailWork               = $curInfo.EmailWork
            FirstName               = $curInfo.FistName
            NMBRSDisplayName        = $curInfo.DisplayName
            #Gender = $curInfo.Gender
            infoId                  = $curInfo.id
            Initials                = $info.Initials
            #IdentificationNumber =  $curInfo.IdentificationNumber
            #IndentificationType = $curInfo.IdentificationType
            LastName                = $curInfo.LastName
            NaamStelling            = $curInfo.Naamstelling
            #NationalityCode = $info.NationalityCode
            NickName                = $curInfo.Nickname
            PartnerLastName         = $curInfo.PartnerLastName
            PartnerPrefix           = $curInfo.PartnerPrefix
            Prefix                  = $curInfo.Prefix
            Startperiod             = $curInfo.StartPeriod
            StartYear               = $curInfo.StartYear
            #TelephonePrivate = $info.TelephonePrivate
            #TelephoneMobilePrivate = $info.TelephoneMobilePrivate
            Title                   = $curInfo.Title
            TitleAfter              = $curInfo.TitleAfter
        }

        $CurPerson | Add-Member -NotePropertyMembers @{ ExternalId = $CurPerson.EmployeeID } -Force
        $CurPerson | Add-Member -NotePropertyMembers @{ DisplayName = $CurPerson.NMBRSDisplayName } -Force
        Write-Output $CurPerson | ConvertTo-Json -Depth 10
    }
}
catch {
    $ex = $PSItem
    Write-verbose -Verbose "Could not retrieve NMBRS employees. Error: $($ex.Exception.Message)"
    Write-verbose -Verbose "Could not retrieve NMBRS employees. ErrorDetails: $($ex.ErrorDetails)"
    throw ($ex)
}
