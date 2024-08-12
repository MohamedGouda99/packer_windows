packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "firstrun-windows" {
  ami_name      = "packer-windows-demo-${local.timestamp}"
  communicator  = "winrm"
  instance_type = "t2.micro"
  region        = var.region

  source_ami_filter {
    filters = {
      name                = "Windows_Server-2019-English-Full-Base-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    owners      = ["amazon"]
    most_recent = true
  }

  user_data_file = "./bootstrap_win.txt"
  winrm_password = "SuperS3cr3t!!!!"
  winrm_username = "Administrator"
}

build {
  name    = "learn-packer"
  sources = ["source.amazon-ebs.firstrun-windows"]

  provisioner "powershell" {
    environment_vars = ["DEVOPS_LIFE_IMPROVER=PACKER"]
    inline           = [
      "Write-Host \"HELLO NEW USER; WELCOME TO $Env:DEVOPS_LIFE_IMPROVER\"",
      "Write-Host \"You need to use backtick escapes when using\"",
      "Write-Host \"characters such as DOLLAR`$ directly in a command\"",
      "Write-Host \"or in your own scripts.\""
    ]
  }

  provisioner "windows-restart" {
    restart_check_command = "powershell -Command \"Get-Service -Name WinRM\""
    restart_timeout      = "10m"
  }

  provisioner "powershell" {
    environment_vars = [
      "VAR1=A$Dollar",
      "VAR2=A`Backtick",
      "VAR3=A'SingleQuote",
      "VAR4=A\"DoubleQuote"
    ]
    script = "./sample_script.ps1"
  }
}
