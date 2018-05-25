#####################################################################################################
# Script written by © Dr. John Tunnicliffe, 2015-2018 https://github.com/DrJohnT/devops-your-dwh
# This PowerShell script is released under the MIT license http://www.opensource.org/licenses/MIT
#
# Functions to build and deploy SSIS projects
#####################################################################################################
		
	function Deploy-SsisSolution ([string] $SolutionName = $(throw "Solution name required.") ) {
		<# 
			.SYNOPSIS
			Deploys the SSIS packages to the target environment using project deployment mode
		#>	
		try
		{
			$SolutionFolderPath = Get-SolutionPath($SolutionName);
			$SolutionFolderPath = split-path $SolutionFolderPath
			
			$solutionNode = $deployConfig.DeploymentConfig.Solutions.Solution | where Name -EQ $SolutionName;
			foreach ($project in $solutionNode.SSIS_Project) {
				$projectPath = Join-Path $SolutionFolderPath $project.Project;
				Deploy-SsisProject -ProjectPath $projectPath -Project $project.Project -Folder $project.Folder;
			}
		} catch {
			logError -Message "Deploy-SsisSolution Failed to deploy solution $SolutionName Error: $_";
		} 
	}

    function Deploy-SsisProject ([string] $projectPath = $(throw "Project path required!"), [string] $project = $(throw "project name required!"), [string] $folder = $(throw "folder name required!")  ) {
		<# 
			.SYNOPSIS 
			Deploys the SSIS project to the target environment using project deployment mode

            Must use isdeploymentwizard.exe to deploy SSIS projecs
            For isdeploymentwizard.exe command-line options see https://docs.microsoft.com/en-us/sql/integration-services/packages/deploy-integration-services-ssis-projects-and-packages

            SSISDB Folder setup with thanks to https://www.hansmichiels.com/2016/11/04/how-to-automate-your-ssis-package-deployment-and-configuration-ssis-series/
		#>		
		try {
    		$ServerName = Get-SsisServerFromConfig;

            $SQLCmdVaribles = Get-SqlCmdVariablesFromConfig -UseServerRoles $false;
            $sqlFilePath = Join-Path $SsisDeploySQLScriptPath "CreateSsisDbFolder.sql";
            assert(Test-Path($sqlFilePath)) "SQL script CreateSsisDbFolder.sql not exist!"

            Run-SqlScriptAgainstServer -ServerName $ServerName -DatabaseName "SSISDB" -SqlFilePath $sqlFilePath -SQLCmdVaribles $SQLCmdVaribles;

			$ispacPath = Join-Path $projectPath "bin\$configuration\$project.ispac";
            assert(Test-Path($ispacPath)) "SSIS ISPAC does not exist in $ispacPath";
            Write-Host "Deploying $project to $folder folder from ispac path $ispacPath" -ForegroundColor Yellow;

			# As this is a windows EXE we need to wait for it to end before applying the scripts, so we pipe to Out-Null 
			exec { &"$SsisDeploymentWizard" /Silent /SourcePath:"$ispacPath" /DestinationServer:"$ServerName" /DestinationPath:"/SSISDB/$folder/$project" | Out-Null }

			
		} catch {
			logError -Message "Deploy-SsisProject Failed to deploy SSIS $project Error: $_";
		}
    }

    function Deploy-SsisEnvironments ([string] $SolutionName = $(throw "Solution name required.") ) {
        <# 
			.SYNOPSIS
			Create an environment in SSISDB for the solution
		#>	
		try {
			$SolutionFolderPath = Get-SolutionPath($SolutionName);
			$SolutionFolderPath = split-path $SolutionFolderPath
			
			$solutionNode = $deployConfig.DeploymentConfig.Solutions.Solution | where Name -EQ $SolutionName;
			foreach ($project in $solutionNode.SSIS_Project) {
				Deploy-SsisEnvironment $project.Project $project.Folder;
			}
		} catch {
			logError -Message "Deploy-SsisEnvironments failed. Error: $_";
		} 
    }

    function Deploy-SsisEnvironment ([string] $project = $(throw "project name required!"), [string] $folder = $(throw "folder name required!")  ) {
        <# 
			.SYNOPSIS
			Create an environment in SSISDB for the project

            SSISDB Environment setup with thanks to https://www.hansmichiels.com/2016/11/04/how-to-automate-your-ssis-package-deployment-and-configuration-ssis-series/
		#>	
		try {
			$ServerName = Get-SsisServerFromConfig;
			$SQLCmdVaribles = Get-SqlCmdVariablesFromConfig -UseServerRoles $false;

			$sqlFilePath = Join-Path $SsisDeploySQLScriptPath "CreateSsisDbEnvironment.sql";
			assert(Test-Path($sqlFilePath)) "SQL script CreateSsisDbEnvironment.sql not exist!"
			Run-SqlScriptAgainstServer -ServerName $ServerName -DatabaseName "SSISDB" -SqlFilePath $sqlFilePath -SQLCmdVaribles $SQLCmdVaribles;

			$sqlFilePath = Join-Path $SsisDeploySQLScriptPath "LinkSsisDbEnvToProject.sql";
			assert(Test-Path($sqlFilePath)) "SQL script LinkSsisDbEnvToProject.sql not exist!"
			Run-SqlScriptAgainstServer -ServerName $ServerName -DatabaseName "SSISDB" -SqlFilePath $sqlFilePath -SQLCmdVaribles $SQLCmdVaribles;    
		} catch {
			logError -Message "Deploy-SsisEnvironment failed. Error: $_";
		} 
    }	
	
    function Drop-SsisFolder {
		<# 
			.SYNOPSIS 
			Drops the SSIS folder
		#>		
		try {
    		$ServerName = Get-SsisServerFromConfig;

            $SQLCmdVaribles = Get-SqlCmdVariablesFromConfig -UseServerRoles $false;
            
            $sqlFilePath = Join-Path $SsisDeploySQLScriptPath "Drop_SsisDb_Folder.sql";
            assert(Test-Path($sqlFilePath)) "SQL script $sqlFilePath does not exist!"
            
            Write-Host "Dropping SSIS folder";

            Run-SqlScriptAgainstServer -ServerName $ServerName -DatabaseName "SSISDB" -SqlFilePath $sqlFilePath -SQLCmdVaribles $SQLCmdVaribles;
		
		} catch {
			logError -Message "Drop-SsisFolder failed to drop folder $folder in SSISDB Error: $_";
		}
    }

    function Invoke-SsisPackage ([string] $SsisPackageName = $(throw "SSIS Package name required!")) {
        <# 
			.SYNOPSIS
			Executes an SSIS package in SSISDB 
		#>	
		try {
		
			$ServerName = Get-SsisServerFromConfig;
			$SQLCmdVaribles = Get-SqlCmdVariablesFromConfig -UseServerRoles $false;
			$SQLCmdVaribles += "SsisPackageName=$SsisPackageName";

			$sqlFilePath = Join-Path $SsisDeploySQLScriptPath "ExecuteSsisPackage.sql";
			assert(Test-Path($sqlFilePath)) "SQL script ExecuteSsisPackage.sql not exist!"

			Write-Host "Running SSIS package $SsisPackageName";
			Run-SqlScriptAgainstServer -ServerName $ServerName -DatabaseName "SSISDB" -SqlFilePath $sqlFilePath -SQLCmdVaribles $SQLCmdVaribles;
		} catch {
			logError -Message "Invoke-SsisPackage failed. Error: $_";
		}
    }
	