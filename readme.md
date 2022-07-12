
# HelloID-Conn-Prov-Source-NMBRS

| :warning: Warning |
|:---------------------------|
| Note that this connector is "a work in progress" and therefore not ready to use in your production environment. |

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |

<p align="center">
  <img src="assets/logo.png">
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
| CompanyId | The companyId for which the employees will be imported | Yes |
|DebtorId | The DebtorId for which the departments will be imported | Yes |
|proxyAddress| The addres of the proxy  |No |
|IsDebug | When toggled, debug logging will be displayed |
### Prerequisites

### Remarks

1) The ExternalID field of the person contains the EmployeeID (MedewerkerId) of the person. This is the Unique key.
2) The EmployeeNumber (MedewerkerNummer) is by default mapped to the "UserName" field.  This field is not unique.
3) Only the "current" value of the Manager, Costcenter, Department, and Function is available, No historic information is available for those entities. This current value is copied to the appropriate fields of each contract, but is not related to the specific contract. (all contracts have the same "current" value for these fields)
4) The contracts themselves do have start and end dates as normal.
5) The call to get the current costcenter is not available at the currently used environment, therefore this is the costcenter at the time specified in the startyear and period of the person.

## Setup the connector

> _How to setup the connector in HelloID.
No special connector specific setup required


## Getting help

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012557600-Configure-a-custom-PowerShell-source-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
