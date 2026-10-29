# Change Log



All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](https://keepachangelog.com), and this project adheres to [Semantic Versioning](https://semver.org).

## [3.0.0] - 2026-10-13
### Added
- no functionality added
### Changed
- Complete conversion from the depricated SOAP API to the new NMBRS REST API
- Authentication mechanism updated to use the OAuth 2.0 protocol. This includes a different set of credentials and token handling compared to the previous SOAP API implementation.
- Modified the configuration to contain the DebtorName and CompanyName instead of the DebtorID and CompanyID. The new configuration requires the user to provide the names rather than the IDs. The Id's are looked up based on the provided names.
- Added helper GetRefreshTokenFromAuthorisationCode.ps1 script for retrieving initial refresh token
- The mapping file has been retained for as much as possible from the previous SOAP API implementation.

### Deprecated
- All SOAP API functionality has been removed

### Removed
- Removed a lot of NMBRS resources to associated HelloID contracts mappings for resource types that where not collected and used.

## [2.0.0] - 2025-11-21

This is the first official release of _HelloID-Conn-Prov-Source-NMBRS_. 

### Added

### Changed

### Deprecated

### Removed