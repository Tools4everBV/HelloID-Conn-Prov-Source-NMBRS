
# HelloID-Conn-Prov-Source-NMBRS

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |
<br /> 
<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/vismanmbrs-logo.png" width="500">
</p> 

## Table of contents

- [Introduction](#Introduction)
- [Getting started](#Getting-started)
  + [Connection settings](#Connection-settings)
  + [Prerequisites](#Prerequisites)
  + [Remarks](#Remarks)
- [Setup the connector](@Setup-The-Connector)
- [Getting help](#Getting-help)
- [HelloID Docs](#HelloID-docs)

## Introduction

_HelloID-Conn-Prov-Source-NMBRS_ is a _source_ connector. NMBRS provides a set of SOAP API's that allow you to programmatically interact with it's data. The HelloID connector uses the API endpoints listed in the table below.

| Endpoint     | Description |
| ------------ | ----------- |
| https://api.nmbrs.nl/soap/v3/EmployeeService.asmx? | info regarding persons, contracts and so on           |
|https://api.nmbrs.nl/soap/v3/DebtorService.asmx?op=Department_GetList| the list of departments for the department script|

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting      | Description                        | Mandatory   |
| ------------ | -----------                        | ----------- |
| UserName     | The UserName to connect to the API | Yes         |
| Token        | The token to connect to the API | Yes         |
| Domain      | The Domain [mydomain.nmbrs.nl] to connect to the API                | Yes         |
| BaseUrl | The URL to the API.[https://api.nmbrs.nl] | Yes |
| Version | The version of the API [v3]               | Yes |
| CompanyId | Comma separated list of companyIds for which the employees will be imported | Yes |
|DebtorId | The DebtorId for which the departments will be imported | Yes |
|EndDateThreshold | The number of days after end date for which contracts will be retrieved | Yes |
|proxyAddress| The addres of the proxy  |No |
|IsDebug | When toggled, debug logging will be displayed |
### Prerequisites

### Remarks

1) The ExternalID field of the person contains the EmployeeID (MedewerkerId) of the person. This is the Unique key.
2) The EmployeeNumber (MedewerkerNummer) is by default mapped to the "UserName" field.  This field is not unique.
3) The current value of the Manager, Costcenter, Department and Function is available. This current value is copied to the appropriate fields of each contract in helloid, but is not related to the specific contract.  (all contracts have the same "current" value for these fields)
4) Historical information is available for NMBRS-contracts, Departments, Functions, Employments and Schedules. This are stored as "contracts" in helloid, where the "contracttype" is one of "Contract, Departments, Functions, Employments and Schedules".
5) For contracts of type "contract", it has been found that there can be multiple contracts with the same Id. If this is the case, the current contract is retreived instead, so there will not be multiple contracts with the same id in the end result.

## Setup the connector

> _How to setup the connector in HelloID.
No special connector specific setup required


## Getting help

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012557600-Configure-a-custom-PowerShell-source-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
