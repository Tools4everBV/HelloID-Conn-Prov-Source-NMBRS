
# HelloID-Conn-Prov-Source-NMBRS

| :information_source: Information                                                                                                                                                                                                                                                                                                                                                       |
| :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as username, password, certificate, etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements. |
<br /> 
<p align="center">
  <img src="https://www.tools4ever.nl/connector-logos/vismanmbrs-logo.png" width="500">
</p> 

## Table of contents

- [HelloID-Conn-Prov-Source-NMBRS](#helloid-conn-prov-source-nmbrs)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
    - [Obtaining API Credentials](#obtaining-api-credentials)
    - [Setup the connector](#setup-the-connector)
  - [Remarks](#remarks)
  - [Development resources](#development-resources)
    - [API endpoints](#api-endpoints)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

_HelloID-Conn-Prov-Source-NMBRS_ is a _source_ connector. NMBRS provides a set of Rest API's that allow you to programmatically interact with it's data. 

## Getting started

### Connection settings

The following settings are required to connect to the API.

| Setting              | Description                                                                                                                                                                                                                                                                                     | Mandatory |
| -------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| BaseUrl              | The URL to the API. e.g. [https://api.nmbrsapp.com/api]                                                                                                                                                                                                                                         | Yes       |
| TokenUrl             | The URL to retrieve the token to connect to the API e.g. [https://identityservice.nmbrs.com/connect/token]                                                                                                                                                                                      | Yes       |
| TokenHost            | The host of the token URL e.g. [identityservice.nmbrs.com]                                                                                                                                                                                                                                      | Yes       |
| ClientId             | The client ID to connect to the API                                                                                                                                                                                                                                                             | Yes       |
| ClientSecret         | The client secret to connect to the API                                                                                                                                                                                                                                                         | Yes       |
| SubscriptionKey      | The subscription ID to connect to the API                                                                                                                                                                                                                                                       | Yes       |
| RefreshToken         | The refresh token to connect to the API. You can generate an initial refresh token by executing the `GetRefreshKeyFromAuthorisationCode.ps1` script and following the instructions to obtain the authorization code. Copy the resulting refresh token and save it in the HelloId Configuration. | Yes       |
| RefreshTokenSaveFile | The file path where the subsequent refresh token will be saved                                                                                                                                                                                                                                  | Yes       |
| CompanyName          | comma separated list of the name(s) of the company /companies to retrieve employees for                                                                                                                                                                                                         | Yes       |
| DebtorName           | comma separated list of the name(s) of the debtor /debtors to retrieve departments for                                                                                                                                                                                                          | Yes       |
| EndDateThreshold     | The number of days after end date for which contracts (employments) will be retrieved                                                                                                                                                                                                           | Yes       |
| proxyAddress         | The addres of the proxy                                                                                                                                                                                                                                                                         | No        |
| IsDebug              | When toggled, debug logging will be displayed                                                                                                                                                                                                                                                   |

In the system tab select the "execute on premises" option.

### Prerequisites

-Have an app definition configured in the Nmbrs partner portal system, which will be used to obtain the necessary credentials for connecting to the API.
-This connector needs file access in order to store and retrieve the refresh token for API authentication. Therefore it requires the HelloID agent service to be installed locally.

### Obtaining API Credentials

For this go to the Nmbrs partner portal (partner-portal.nmbrsapp.com/) and login with your partner credentials. Then navigate to the "My Integrations" section and create a new app 
definition, or use an existing one to obtain the necessary credentials. Here you will find the **ClientId**, and can create a **ClientSecret** for the app definition. 
Set the redirect URI to http://localhost:8080, or an other unused local URL for the app definition. 

In the same partner portal, you will also need to register a subscription to access the API.  This can be found in the Products section, where you can add a new Subscription. Select and open the appropriate subscription type for your Nmbrs environment. Here you will find a list of your existing subscriptions of the selected kind, and also can create a new one if needed.  Note, this page will show only the Subscription name and not the Subscription key itself. You will need to navigate to your user profile to find more detailed information of your subscriptions.  Here you can find the Subscription key. The **SubscriptionKey** needed for the connection is the value listed as the Primary Key of the subscription.

### Setup the connector

- Provide the **Client ID**, **Client Secret**, and **Subscription key** obtained from the Nmbrs partner portal.
- Provide the Company name(s) and debtorname(s) from your Nmbrs payroll environment from which you want to import the employees and department. (select Instellingen > beheer > bedrijven beheer). There may be no separate debtors listed, in which case use the company name as the debtor name also.
- specify the path to the file where the active refresh token will be saved: **RefreshTokenSaveFile**. This file will be used by the connector to store and retrieve the refresh token for API authentication. 

- Generate an initial refresh token by customizing and executing the **GetRefreshKeyFromAuthorisationCode.ps1** example script after following the instructions therein to obtain the authorization code. Copy the resulting refresh token and save it in the HelloId Configuration. Take care to execute this step securely and avoid exposing the client secret or refresh token.

- Make sure that you do not use the refresh token obtained in this step manually outside of the HelloId connector. NMBRS invalidates and regenerates a new one after each use.  
 
- After the connector has been configured and executed for the first time, it will automatically manage the refresh token and access token for subsequent API authentication. 

- If for some reason the refresh token becomes invalid or expired, Delete the old tokenfile from the location specified by the **RefreshTokenSaveFile** configuration and manually generate a new one using the **GetRefreshKeyFromAuthorisationCode.ps1** script and replace the old refresh token in the HelloId configuration with the newly obtained one. If you do not have delete rights, specify a new location for the refresh token file also. 

## Remarks

1. The connector uses the refresh token specified in the configuration to initially retrieve a new access token for API authentication. This process is handled automatically by the connector, and the refresh token is updated after each successful retrieval of a new access token. The encrypted value of the updated access token is stored in the location specified by the **RefreshTokenSaveFile** configuration, this ensures that the connector can continue to authenticate with the API without manual intervention.

2. There are currently no failsafe safeguards implemented to prevent the simultaneous execution of the "Persons" and the "Departments" scripts which could potentially lead to race conditions when accessing and updating the refresh token. HelloId is likely to start both scripts concurrently. Therefore there is added a delay to the execution of the persons script to mitigate the risk of such race conditions, but it is not a guaranteed solution. You may need to increase the delay if race conditions are observed.  

3. The ExternalID field of the person contains the EmployeeID (MedewerkerId) of the person. This is the Unique key.  
4. The EmployeeNumber (MedewerkerNummer) field is populated with a combination of the company ID and the employee number from Nmbrs.
5. The current value of the Manager, Costcenter, Department and Function is available. This current value is copied to the appropriate fields of each contract in helloid, but is not related to the specific contract.  (all contracts have the same "current" value for these fields)
6. Historical information is available for Employments. These are stored as "contracts" in helloid, where the "contracttype" is one of "Employments". 
7. The Naamstelling field contains the ascription of the person, which is retrieved from the partner information in Nmbrs.
 
    The interpretation of this field is as follows:

    | Value | Description               |
    | ----- | ------------------------- |
    | 1     | Only own name             |
    | 2     | Only partner's name       |
    | 3     | 'partner name - own name' |
    | 4     | 'own name - partner name' |

> [!IMPORTANT] Not all personal information fields that were available and used in the previous NMBRS numbers connector that used the SOAP API are available in the Nmbrs REST API. At the moment of this development, therefore. Some personal information fields may be missing when imported into HelloId. At the moment of this development, these are the following fields: 'Title' and 'TitleAfter'.
> [!IMPORTANT] The EmployeeID returned by the Rest API differs from the EmployeeID returned by the SOAP API in the previous SOAP API connector. You may need to unmanage existing target systems before importing employees with the new connector to avoid conflicts.

## Development resources

API documentation for Nmbrs REST API:

https://nmbrs.stoplight.io/docs/nmbrs-restapi/9c14f1c024642-getting-started

### API endpoints

| Endpoint                                     | Description                                          |
| -------------------------------------------- | ---------------------------------------------------- |
| /companies                                   | Retrieve a list of companies                         |
| /companies/{companyId}/employees             | Retrieve list of employees for a specific company    |
| /companies/{companyId}/employees/employments | Retrieve list of employments for a specific company  |
| /companies/{companyId}/employees/costcenters | Retrieve list of cost centers for a specific company |
| /debtors                                     | Retrieve a list of debtors                           |
| /debtors/{debtorId}/departments              | Retrieve a list of departments for a specific debtor |
| /employees/{employeeId}                      | Retrieve details for a specific employee             |


## Getting help

> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012557600-Configure-a-custom-PowerShell-source-system) pages_

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
