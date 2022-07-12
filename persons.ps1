########################################################################
# HelloID-Conn-Prov-Source-NMBRS-Persons
#
# Version: 1.0.0
########################################################################
# Initialize default value's
$config = $Configuration | ConvertFrom-Json

# Set debug logging
switch ($($config.IsDebug)) {
    $true { $VerbosePreference = 'Continue' }
    $false { $VerbosePreference = 'SilentlyContinue' }
}

#region internal functions
function Invoke-NMBRSRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $Uri,

        [Parameter()]
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
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}


#endregion internal functions

#region external functions

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
function Get-ContractsbyCompany {

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

function Find-ContractsOfEmployee {
    [CmdletBinding()]
    param (
         [Parameter(Mandatory)]
        [System.Collections.Generic.List[Object]]
        $ContractList,

        [Parameter(Mandatory)]
        [string]
        $EmployeeID
    )

    $foundContracts = [System.Collections.Generic.List[Object]]::new()
    foreach ($ContractItem in $ContractList)
    {
        if ($ContractItem.EmployeeID -eq $EmployeeID)
        {
            foreach ($Contract in $ContractItem.EmployeeContracts.ChildNodes)
            {
                $foundContracts.add($Contract)
            }
        }
    }
    return ,$foundContracts
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

function Get-CurrentFunction
{
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

function Get-CurrentManager
{
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

function Get-Costcenter
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $EmployeeId,

        [Parameter(Mandatory)]
        [string]
        $Period,

        [Parameter(Mandatory)]
        [string]
        $Year
    )

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/EmployeeService.asmx"
        Service  = 'EmployeeService'
        SoapBody = "<emp:CostCenter_Get xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/EmployeeService`">
            <emp:EmployeeId>$EmployeeId</emp:EmployeeId>
            <emp:Period>$Period</emp:Period>
            <emp:Year>$Year</emp:Year>
            </emp:CostCenter_Get>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Costcenter_GetResponse.Costcenter_GetResult.EmployeeCostcenter
}

#endregion external functions

try {
    Write-Verbose 'Retrieving NMBRS employee data'
    $persons = [System.Collections.Generic.List[Object]]::new()

    $personalInformation = Get-PersonalInfoWithoutBSN
    $ContractList   = Get-ContractsbyCompany($config.CompanyId)
    #optional todo convert to hashtable to improve search performance

      foreach ($NMBRS_Employee in $personalInformation) {

        $curEmployeeId = $NMBRS_Employee.EmployeeId
        Write-Verbose "Retrieving NMBRS employee data for EmployeeID [$curEmployeeId]"

        $curInfo = $null
        foreach ($info in $NMBRS_Employee.EmployeePersonalInfos.ChildNodes)   {
            if (($null -eq $Curinfo) -or ($curInfo.CreationDate -lt $info.CreationDate))
            {
                $curInfo = $info
            }
        }

        $getFunctionResult  = Get-CurrentFunction ($curEmployeeId)
        $getDepartmentResult  = Get-CurrentDepartment ($curEmployeeId)
        $getManagerResult  = Get-CurrentManager ($curEmployeeId)
        $getCostcenterResult  = Get-Costcenter -EmployeeID $curEmployeeId -Period $curInfo.StartPeriod -Year $curInfo.StartYear
        $employeeContracts = Find-ContractsOfEmployee -ContractList $ContractList -EmployeeID $curEmployeeId

        $Contracts = [System.Collections.Generic.List[Object]]::new()
        foreach ($employeeContract in  $employeeContracts) {
            $manager = @{
                Department = $getManagerResult.Department
                Email = $getManagerResult.Email
                FirstName = $getManagerResult.FirstName
                Name = $getManagerResult.Name
                Number =  $getManagerResult.Number
            }

            $department = @{
                Code =  $getDepartmentResult.Code
                ID = $getDepartmentResult.Id
                Description = $getDepartmentResult.Description
            }

            $function = @{
                Code = $getFunctionResult.Code
                Description = $getFunctionResult.Description
                ID =$getFunctionResult.Id

            }

            $costCenter = @{
                Code =  $GetCostcenterResult.Costcenter.Code
                Description = $GetCostcenterResult.Costcenter.Description

            }

            $kostensoort =@{
                Code = $GetCostcenterResult.Kostensoort.Code
                Description = $GetCostcenterResult.Kostensoort.Description
            }

            $employeeCostCenter = @{
                CostCenter = $CostCenter
                Kostensoort = $Kostensoort
                ID = $GetCostcenterResult.Id
                Percentage =  $GetCostcenterResult.Percentage
                default = $GetCostcenterResult.default
            }

            $curContract = @{
                ExternalId = $employeeContract.contractID
                ContractID = $employeeContract.contractID
                CreationDate = $employeeContract.CreationDate
                CurrentDepartment = $department
                CurrentEmployeeCostcenter = $employeeCostCenter
                CurrentFunction = $function
                CurrentManager = $manager
                EndDate = $employeeContract.EndDate
                EmploymentType = $employeeContract.EmployementType   # typo in api Employement instead of Employment
                EmploymentSequenceTaxId = $employeeContract.EmploymentSequenceTaxId
                Indefinite =  $employeeContract.Indefinite
                PhaseClassification = $employeeContract.PhaseClassification
                Startdate = $EmployeeContract.Startdate
                TrialPeriod = $EmployeeContract.TrialPeriod
                WrittenContract = $employeeContract.WrittenContract
                HoursPerWeek = $employeeContract.HoursPerWeek
            }
            $Contracts.add($CurContract)
        }

        $CurPerson = @{
            BurgerlijkeStaat = $curInfo.BurgerlijkeStaat
            #Birthday = $curInfo.Birthday
            Contracts = $Contracts
            CreationDate = $curInfo.CreationDate
            #CountryOfBirthISOCode =$curInfo.CountryOfBirthISOCode
            EmployeeID = $curEmployeeId
            EmployeeNumber = $curInfo.EmployeeNumber
            EmailWork = $curInfo.EmailWork
            FirstName = $curInfo.FistName
            NMBRSDisplayName = $curInfo.DisplayName
            #Gender = $curInfo.Gender
            infoId = $curInfo.id
            Initials = $info.Initials
            #IdentificationNumber =  $curInfo.IdentificationNumber
            #IndentificationType = $curInfo.IdentificationType
            LastName = $curInfo.LastName
            NaamStelling = $curInfo.Naamstelling
            #NationalityCode = $info.NationalityCode
            NickName = $curInfo.Nickname
            PartnerLastName = $curInfo.PartnerLastName
            PartnerPrefix = $curInfo.PartnerPrefix
            Prefix = $curInfo.Prefix
            Startperiod =   $curInfo.StartPeriod
            StartYear =     $curInfo.StartYear
            #TelephonePrivate = $info.TelephonePrivate
            #TelephoneMobilePrivate = $info.TelephoneMobilePrivate
            Title = $curInfo.Title
            TitleAfter = $curInfo.TitleAfter
        }
            $persons.add($CurPerson)
    }
    # Write-Verbose 'Importing raw data in HelloID'
    foreach ($person in $persons) {
        $person | Add-Member -NotePropertyMembers @{ ExternalId = $person.EmployeeID } -Force
        $person | Add-Member -NotePropertyMembers @{ DisplayName = $person.NMBRSDisplayName } -Force
         Write-Output $person | ConvertTo-Json -Depth 10
    }
}
catch {
  $ex = $PSItem
  Write-Verbose "Could not retrieve NMBRS employees. Error: $($ex.Exception.Message)"
  Write-Verbose "Could not retrieve NMBRS employees. ErrorDetails: $($ex.ErrorDetails)"

}
