# Packer Configuration for Windows AMI

This repository contains a Packer configuration file to build a Windows AMI on AWS using Packer. The configuration includes the setup of a Windows Server 2019 instance, provisioning with PowerShell, and configuration of user data and WinRM settings.

## Packer Configuration Overview

- **Packer Version**: The configuration requires the `amazon` plugin version `>= 0.0.1`.
- **Region**: The default AWS region is set to `us-east-1`.

### Configuration Details

- **AMI Name**: The resulting AMI will be named `packer-windows-demo-${timestamp}`, where `${timestamp}` is a dynamically generated timestamp.
- **Instance Type**: `t2.micro`.
- **Source AMI Filter**: The source AMI is a Windows Server 2019 English Full Base image.
- **WinRM Settings**: 
  - **Username**: `Administrator`
  - **Password**: `SuperS3cr3t!!!!`

### Provisioners

1. **PowerShell Provisioner**:
   - Sets environment variables and executes inline commands to display a welcome message.
   - Escapes special characters like `$` in commands.

2. **Windows Restart Provisioner**:
   - Restarts the instance to apply changes and checks if the WinRM service is running.

3. **PowerShell Script Provisioner**:
   - Executes a PowerShell script `sample_script.ps1` for additional configuration.

## Prerequisites

- [Packer](https://www.packer.io/downloads) installed on your local machine.
- AWS CLI configured with appropriate permissions.

## How to Execute

1. **Initialize Packer**:
   Initialize the Packer environment and download the required plugins.
   ```bash
   packer init .
   packer validate windows.pkr.hcl
   packer build windows.pkr.hcl
   ```
