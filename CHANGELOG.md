# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- New Interface with Visual Studio Project. Extending with PowerShell where needed. Basic C# is working, but i will mainly used this for PowerShell.
- Passwort + Active Directory Admin Authentication (Authentication itself will be implemented via PowerShell)
  - https://www.systanddeploy.com/2019/12/task-sequence-password-protect-gui-for.html
  - https://github.com/damienvanrobaeys/TS_AD_Protect\
- Win OS + Build and Release Number
- More User Information (DNSDomain)
- Memory Slots

### Changed
- Changed WIM to CIM, well catually combined, but using CIM when available.
- Virus Information in "Details"-Tab not working with external Tools. Is working now. Might still need some tweaks!!
- Changed/Added WiFi "N/A" Status when there is no WiFi-Component installed (like my main machine)
- Moved first WMI/CIM after the launch auf the loading screen.
- Fixed the IPAddress in Details-Tab, showing the wrong card (Hyper-V/VMWare create multiple...)

### Removed