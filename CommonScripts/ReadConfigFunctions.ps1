#####################################################################################################
# Script written by © Dr. John Tunnicliffe, 2015-2018 https://github.com/DrJohnT/devops-your-dwh
# This PowerShell script is released under the MIT license http://www.opensource.org/licenses/MIT
#
# FUNCTIONS TO READ Config.xml held in $deployConfigFileName
#####################################################################################################

#region Get Config Functions
	function GetTargetEnviromentNode() {
		return $deployConfig.DeploymentConfig.Environments.Environment | where Name -EQ $targetEnvironment;
	}
	
	function Get-SolutionPath([string] $SolutionName = $(throw "Solution name required.") ) {
		# returns the path to the named solution
		
		Write-Debug "Getting path to solution $SolutionName";
		
		try {
			$solutionNode = $deployConfig.DeploymentConfig.Solutions.Solution | where Name -EQ $SolutionName;
			$SolutionPath = Join-Path $RootPath	$solutionNode.GetAttribute("SolutionPath");
		} catch {
			logError -Message "ERROR: Solution '$SolutionName' does not exist in $deployConfigFileName Error: $_";
		}
		#assert(Test-Path($SolutionPath)) "Solution must exist in $SolutionPath";
		
		return $SolutionPath;
	}
	
	function Get-DatabaseServerFromConfig([string] $serverRole = $(throw "ServerRole required")) {
		$targetEnvNode = GetTargetEnviromentNode;
		# find the server we need to deploy to for each role
		$serverNode = $targetEnvNode.Servers.Server | where { $_.ServerRoles.Role -EQ $serverRole }
		[string] $ServerName = $serverNode.GetAttribute("name");
		return $ServerName;
	}

	function Get-DatabaseServerRoleFromConfig([string] $DatabaseName = $(throw "Database name required")) {
		$databaseNode = $deployConfig.DeploymentConfig.Databases.Database | where {$_.GetAttribute("name") -EQ $DatabaseName};
		[string] $serverRole = $databaseNode.GetAttribute("ServerRole");
		return $serverRole;
	}

	function GetProperty-AlwaysCreateNewDatabase([string] $DatabaseName = $(throw "Database name required")) {
		$propertyValue = GetProperty-Database -DatabaseName $DatabaseName -PropertyName "AlwaysCreateNewDatabase" -Default "False"
		return $propertyValue;
	}
	
	function GetProperty-Database([string] $DatabaseName = $(throw "Database name required"),
		[string] $propertyName = $(throw "Property name required"),
		[string] $defaultValue = $(throw "Default Value Required")) {
		$databaseNode = $deployConfig.DeploymentConfig.Databases.Database | where {$_.GetAttribute("name") -EQ $DatabaseName};
		[string] $propertyValue = $databaseNode.GetAttribute($propertyName);
		if ($propertyValue -eq "") {
			$propertyValue = $defaultValue;
		}
		return $propertyValue;
	}	
	
	function Get-DatabaseServerNameFromConfig([string] $DatabaseName = $(throw "Database name required")) {
		$serverRole = Get-DatabaseServerRoleFromConfig($DatabaseName);		
		return Get-DatabaseServerFromConfig($serverRole);
	}
	
	function Get-SourceDatabaseForSsasFromConfig([string] $DatabaseName = $(throw "Database name required")) {
		$databaseNode = $deployConfig.DeploymentConfig.Databases.Database | where {$_.GetAttribute("name") -EQ $DatabaseName};
		$sourceDatabaseName = $databaseNode.GetAttribute("SourceDatabase");
		return $sourceDatabaseName;
	}	

	function Get-MappedDatabaseNameFromConfig([string] $DatabaseName = $(throw "Database name required")) {
		# returns the database alias for each database etc.
		if ($DatabaseName -eq "msdb" -or $DatabaseName -eq "master") {
			$MappedDatabaseName = $DatabaseName;
        } else {
			$targetEnvNode = GetTargetEnviromentNode;
			$mappingNode = $targetEnvNode.SelectSingleNode("./DatabaseMapping[@name = '$DatabaseName']")
			if ($mappingNode) {
					$MappedDatabaseName = $mappingNode.GetAttribute("newName");
			} else {
					$MappedDatabaseName = $DatabaseName;
			}           
			Write-Debug "Mapping $DatabaseName to $MappedDatabaseName";
		}
		return $MappedDatabaseName;
	}

	function Get-AnalysisServicesServerFromConfig() {
		$targetEnvNode = GetTargetEnviromentNode;
		# find the server we need to deploy to for each role
		$serverNode = $targetEnvNode.Servers.Server | where { $_.HostedAppTiers.AppTier -EQ "SSAS" }
		return $serverNode.GetAttribute("name");
	}

	function Get-SsisServerFromConfig() {
		$targetEnvNode = GetTargetEnviromentNode;
		# find the server we need to deploy to for each role
		$serverNode = $targetEnvNode.Servers.Server | where { $_.HostedAppTiers.AppTier -EQ "SSIS" }
		return $serverNode.GetAttribute("name");
	}
	
	function Get-SsrsServerFromConfig() {
		$targetEnvNode = GetTargetEnviromentNode;
		# find the server we need to deploy to for each role
		$serverNode = $targetEnvNode.Servers.Server | where { $_.HostedAppTiers.AppTier -EQ "SSRS" }
		return $serverNode.GetAttribute("name");
	}


	function Get-SQLCmdVariable ([string] $name) {
		$targetEnvNode = GetTargetEnviromentNode;
		
		$variable = $targetEnvNode.SQLCmdVariables.SQLCmdVariable | where { $_.GetAttribute("Include") -EQ $name }
		$variableValue = $variable.Value
		Write-Debug "Get-SQLCmdVariable $name=$variableValue"
		return $variableValue;
	}


#endregion