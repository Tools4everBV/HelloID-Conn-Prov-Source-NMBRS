########################################################################
# HelloID-Conn-Prov-Source-NMBRS-Departments
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

#region functions

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

        'DebtorService'{
            $soapHeader = "
            <deb:AuthHeaderWithDomain>
                <deb:Username>$($config.UserName)</deb:Username>
                <deb:Token>$($config.Token)</deb:Token>
                <deb:Domain>$($config.Domain)</deb:Domain>
            </deb:AuthHeaderWithDomain>"

        }
    }

    $xmlRequest = "<?xml version=`"1.0`" encoding=`"utf-8`"?>
        <soap:Envelope xmlns:soap= `"http://www.w3.org/2003/05/soap-envelope`" xmlns:deb=`"https://api.nmbrs.nl/soap/$($config.version)/$service`">
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
        
        Invoke-RestMethod @splatParams -Verbose:$false
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

function Get-DepartmentsbyDebtor {

    [CmdletBinding()]
    param ( [Parameter(Mandatory)]
    [string]
    $DebtorId)

    $splatParams = @{
        Uri      = "$($config.BaseUrl)/soap/$($config.version)/DebtorService.asmx"
        Service  = 'DebtorService'
        SoapBody = "<deb:Department_GetList xmlns=`"https://api.nmbrs.nl/soap/$($config.version)/DebtorService`">
            <deb:DebtorId>$DebtorId</deb:DebtorId>
            </deb:Department_GetList>"
    }
    [xml]$response = Invoke-NMBRSRestMethod @splatParams
    Write-Output $response.Envelope.Body.Department_GetListResponse.Department_GetListResult.Department
}


#endregion

try {
    Write-Verbose 'Retrieving NMBRS Department data'

    $departments = [System.Collections.Generic.List[Object]]::new()

    $departmentList   = Get-DepartmentsbyDebtor($config.DebtorID)

    foreach ($department in $departmentList)
    {
        $curDepartment = @{
                Id          =   $department.Id
                Code        =   $department.Code
                Description =   $department.Description
        }
        $departments.add($curDepartment)
    }

    Write-Verbose 'Importing raw data in HelloID'
    foreach ($department in $departments ) {

        $department | Add-Member -NotePropertyMembers @{ ExternalId = $department.Id } -Force
        $department | Add-Member -NotePropertyMembers @{ DisplayName = $department.Description} -Force
        Write-Output $department | ConvertTo-Json -Depth 10
    }
}
catch {
    $ex = $PSItem
    Write-Verbose "Could not retrieve NMBRS employees. Error: $($ex.Exception.Message)"
    Write-Verbose "Could not retrieve NMBRS employees. ErrorDetails: $($ex.ErrorDetails)"
}
