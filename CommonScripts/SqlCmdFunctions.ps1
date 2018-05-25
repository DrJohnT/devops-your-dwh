#####################################################################################################
# Script written by © Dr. John Tunnicliffe, 2015-2018 https://github.com/DrJohnT/devops-your-dwh
# This PowerShell script is released under the MIT license http://www.opensource.org/licenses/MIT
#
# SQLCmd Functions to run SQL Scripts
#####################################################################################################
<#
 If you get the error 
	“The term 'Invoke-ASCmd' is not recognized as the name of a cmdlet, function, script file, or operable program.”
 then you must install the latest SqlServer module in PowerShell.

 To do this, open PowerShell in administrator mode and run:
	Install-Module -Name SqlServer -AllowClobber -Force -RequiredVersion 21.0.17199  # MUST be this version as new version does not work!!!!!
#>
	
	function Run-SqlScriptsForSpecificDatabase ([string] $sqlFolderPath = $(throw "SqlFolderPath required"),
		[string] $DatabaseName = $(throw "DatabaseName required")) {
		<# 
			.SYNOPSIS 
			Finds the folder for the specific databases below $sqlFolderPath and runs all SQL scripts found in all 
			sub-directories of that folder. Sub-folder name can be either match $DatabaseName or be in the format xx_databaseName (e.g. 01_Archive)
		#>	
		if (Test-Path $sqlFolderPath) {
			$directories = Get-ChildItem -Path "$sqlFolderPath";
			foreach ($directory in $directories) {
				[string] $directoryName = $directory.Name;
				if ($directoryName -eq $DatabaseName) {
					Run-SqlScriptsInFolder -SqlFolderPath $directory.FullName -DatabaseName $DatabaseName
				} else {
					$directoryName = $directoryName.Substring(3);
					if ($directoryName -eq $DatabaseName) {
						Run-SqlScriptsInFolder -SqlFolderPath $directory.FullName -DatabaseName $DatabaseName
					}
				}
			}
		} else {
			logWarning -Message "WARNING: Run-SqlScriptsForSpecificDatabase: Path does not exist: $sqlFolderPath";
		}
	}

    function Run-SqlScriptsInFolderOrder ([string] $sqlFolderPath = $(throw "SqlFolderPath required")) {
		<# 
			.SYNOPSIS 
			Runs all SQL scripts found in all sub-directories of $sqlFolderPath if the folder exists, no error otherwise
			Extracts the database name from the sub-folder name which is expected to be in the format xx_databaseName (e.g. 01_Archive)
		#>	
		if (Test-Path $sqlFolderPath) {
			$directories = Get-ChildItem -Path "$sqlFolderPath";
			foreach ($directory in $directories) {
				[string] $DatabaseName = $directory.Name;
				
				$DatabaseName = $DatabaseName.Substring(3);
				Run-SqlScriptsInFolder -SqlFolderPath $directory.FullName -DatabaseName $DatabaseName
			}
		} else {
			logWarning -Message "WARNING: Run-SqlScriptsInFolderOrder Path does not exist: $sqlFolderPath";
		}
	}
	
	function Run-SqlScriptsInFolder ([string] $sqlFolderPath = $(throw "SqlFolderPath required"),	
		[string] $DatabaseName = $(throw "DatabaseName required")) {
		<# 
			.SYNOPSIS 
			Runs all SQL scripts found in all sub-directories of $sqlFolderPath if the folder exists, no error otherwise
		#>	
		if (Test-Path $sqlFolderPath) {
			$SQLCmdVaribles = Get-SqlCmdVariablesFromConfig($false);

			$ServerName = Get-DatabaseServerRoleFromConfig($DatabaseName);
			
			# now find all the SQL scripts in the deployment folder
			$sqlFiles = Get-ChildItem -Path "$sqlFolderPath\*.sql" -Recurse 
			foreach ($sqlFile in $sqlFiles) {
				[string]$sqlFilePath = $sqlFile;  # $sqlFile is a System.IO.FileInfo object, so cannot use substring
				
				$ServerName = Get-DatabaseServerNameFromConfig($DatabaseName);
				if ($ServerName -ne $null -and $ServerName -ne "") {
					Run-SqlScript -DatabaseName $DatabaseName -SqlFilePath $sqlFilePath -SQLCmdVaribles $SQLCmdVaribles;			
				} else {
					throw ("Run-SqlScriptsInFolder Error: failed to find server for database $DatabaseName from file folder path $sqlFilePath");
				}
			}
		} else {
			logWarning -Message "WARNING: Run-SqlScriptsInFolder: Path does not exist: $sqlFolderPath";
		}
	}
	
	function Run-SqlScript ([string] $DatabaseName = $(throw "DatabaseName required"),
		[string] $sqlFilePath = $(throw "sqlFilePath required"), 
		[array] $SQLCmdVaribles = $(throw "SQLCmdVaribles required")) {
		<# 
			.SYNOPSIS 
			Runs the SQLCmd script $sqlFilePath, passing in the SQLCmd Varibles
		#>	
        $ServerName = Get-DatabaseServerNameFromConfig($DatabaseName);				

		Run-SqlScriptAgainstServer -ServerName $ServerName -DatabaseName $DatabaseName -SqlFilePath $sqlFilePath -SQLCmdVaribles $SQLCmdVaribles;
	}
	
	function Run-SqlScriptAgainstServer ([string] $ServerName = $(throw "Server name required"),
		[string] $DatabaseName = $(throw "DatabaseName required"),
		[string] $sqlFilePath = $(throw "sqlFilePath required"), 
		[array] $SQLCmdVaribles = $(throw "SQLCmdVaribles required")) {
		<# 
			.SYNOPSIS 
			Runs the SQLCmd script $sqlFilePath, passing in the SQLCmd Varibles against the specific server.
			
			.NOTES
			If Invoke-Sqlcmd fails, check what modules are installed using
				Get-Module -ListAvailable
            You should see SqlServer listed as a module.  If not, run
                .\InstallSqlServerModule.ps1
		#>			
		$MappedDatabaseName = Get-MappedDatabaseNameFromConfig -DatabaseName $DatabaseName;
		$fileName = Split-Path $sqlFilePath -Leaf;

		# check the database actually exists - we may be running a pre-deploy on LOCAL, so database may not exist
		if (DoesDatabaseExist -ServerName $ServerName -DatabaseName $MappedDatabaseName) {
                Write-Host("Applying SQL Script '$fileName' against database '$MappedDatabaseName' on server '$ServerName'");
 				try {
					Invoke-Sqlcmd -ServerInstance $ServerName -Database $MappedDatabaseName -InputFile "$sqlFilePath" `
						-QueryTimeout 60000 -Variable $SQLCmdVaribles | out-null; 
				} catch [Exception] {
        	        logError -Message "Database error: $_.Exception";
				}
		} else {
			logWarning -Message "Database '$MappedDatabaseName' does not exist. SQLCmd script '$fileName' will not be run.";
		}		
	}	

	function DoesDatabaseExist ([string] $ServerName = (throw "Server Name required"), [string] $DatabaseName = (throw "Database name required")) {
		if ($ServerName -eq $null -or $ServerName -eq "") {
            return $false; 
		}

        if ($DatabaseName -eq "msdb" -or $DatabaseName -eq "master") {
            return $true;
        }

		[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SMO") | Out-Null;
		$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $ServerName;
		
		try {
			$database = $server.Databases[$DatabaseName];
			if ($database.Name -eq $DatabaseName) {
				return $true;
			} else { 
				return $false; 
			}
		} catch { return $false; }
	}


	function Start-SQLAgentJob ([string] $serverRole = $(throw = "Server Role Required!"),
		[string] $jobName = $(throw = "Job Name Required!")) {
		<# 
			.SYNOPSIS 
			Runs the SQL Agent Job $jobName on server $serverRole
		#>	
		$ServerName = Get-DatabaseServerFromConfig($serverRole);
		$SQLCmdVaribles = @();
		$SQLCmdVaribles += "JobName=$jobName";

        $sqlFilePath = Join-Path $SsisDeploySQLScriptPath "ExecuteSqlAgentJobSynchronously.sql";
        assert(Test-Path($sqlFilePath)) "SQL script ExecuteSqlAgentJobSynchronously.sql not exist!"

        Write-Host "Running Job package $jobName against sever $ServerName";
        Run-SqlScriptAgainstServer -ServerName $ServerName -DatabaseName "msdb" -SqlFilePath $sqlFilePath -SQLCmdVaribles $SQLCmdVaribles;
	}


	function ApplyUserPermissions-SsdtSolutionDatabases ([string] $SolutionName) {
		<#
			.SYNOPSIS
			Applies all user permissions scripts to all databases in the solutions.
		#>	
		$solutionNode = $deployConfig.DeploymentConfig.Solutions.Solution | where Name -EQ $SolutionName;
		foreach ($database in $solutionNode.Database) {		
			ApplyUserPermissionsToDatabase -DatabaseName $database;
		}
	}	
	
	function ApplyUserPermissionsToDatabase ([string] $DatabaseName =  $(throw "Database name required.")) {
		<#
			.SYNOPSIS
			Applies all user permissions scripts to the named database.  The user permissions scripts must be placed 
			in the $SqlScriptPath\UserPermissions\PROD\$DatabaseName folder where PROD =  $EnvironmentGroup
			Note that the scripts can reference the standard SQLCmd variables returned by Get-SqlCmdVariablesFromConfig()
        #>		
		if ($targetEnvironment -eq "LOCAL") {			
			logInfo -Message "User permission scripts are never applied to LOCAL environment";
			return;
		}

		$serverRole = Get-DatabaseServerRoleFromConfig($DatabaseName);
		$ServerName = Get-DatabaseServerNameFromConfig($DatabaseName);

		$SQLCmdVaribles = Get-SqlCmdVariablesFromConfig($true);

		$AddUserGroupToRoleScript = "$SqlScriptPath\UserPermissions\AddUserGroupToRole.sql";
		Write-Debug "ApplyUserPermissionsToDatabase reading files in $AddUserGroupToRoleScript";
		
		if (Test-Path $AddUserGroupToRoleScript)
		{
			$csvFolder = "$SqlScriptPath\UserPermissions\ALL";
			if (Test-Path $csvFolder) {
				$csvFilePath = Join-Path $csvFolder "$DatabaseName.UserPermissions.csv";
				ProcessUserPermissionsCSV $csvFilePath;
			}
			$csvFolder = "$SqlScriptPath\UserPermissions\$EnvironmentGroup";
			if (Test-Path $csvFolder) {
				$csvFilePath = Join-Path $csvFolder "$DatabaseName.UserPermissions.csv";
				ProcessUserPermissionsCSV $csvFilePath;
			}
		}
	}
	
	function ProcessUserPermissionsCSV ([string] $csvFilePath =  $(throw "CSV file path required.")) {
		if (Test-Path $csvFilePath) {
			Write-Host "Reading $csvFilePath" -foregroundcolor Yellow;
					
				
			Import-Csv $csvFilePath | ForEach-Object {
				$UserGroup =  $_.UserGroup;
				$RoleName = $_.RoleName;
				$DefaultSchemaName = $_.DefaultSchemaName;
										
				$SQLCmdVaribles = @();
				$SQLCmdVaribles += "UserGroup=$UserGroup";
				$SQLCmdVaribles += "RoleName=$RoleName";
				$SQLCmdVaribles += "DefaultSchemaName=$DefaultSchemaName";
				Write-Host "Adding '$UserGroup' to role '$RoleName'" -foregroundcolor Cyan;
				Run-SqlScript -DatabaseName $DatabaseName -SqlFilePath $AddUserGroupToRoleScript -SQLCmdVaribles $SQLCmdVaribles;
			}
		}
	}
