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
  winrm_password = vault("secret/data/packer", "winrm_password")
  winrm_username = vault("secret/data/packer", "winrm_username")
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
  winrm_password = local.winrm_password
  winrm_username = local.winrm_username
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
    script = "./sample_script.ps1"
  }
}
