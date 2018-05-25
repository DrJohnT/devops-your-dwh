#####################################################################################################
# Script written by © Dr. John Tunnicliffe, 2015-2018 https://github.com/DrJohnT/devops-your-dwh
# This PowerShell script is released under the MIT license http://www.opensource.org/licenses/MIT
#
# Wrapper around Octopus Deploy
#####################################################################################################

Param (
	[Parameter(Mandatory=$True)]
	[string]$TaskName
)

# install the psake PowerShell module as this may not be installed on the Octopus Deploy build server

[string]$CommonScriptsPath = ".\..\..\CommonScripts";
[string]$psakePath = Resolve-Path "$CommonScriptsPath\psake\psake.psm1";
		
Write-host "Installing PSake module from $psakePath";
		
Import-Module $psakePath;

Invoke-psake -taskList $TaskName;