#####################################################################################################
# Script written by © Dr. John Tunnicliffe, 2015-2018 https://github.com/DrJohnT/devops-your-dwh
# This PowerShell script is released under the MIT license http://www.opensource.org/licenses/MIT
#
# Builds solutions using MsBuild or DevEnv (i.e. Visual Studio)
#####################################################################################################


	function Build-Solution ([string] $SolutionName = $(throw "Solution name required.") ) {
		<# 
			.SYNOPSIS 
			Builds a Visual Studio solution including all databases and C# components.
            However, this will not build the SSIS, SSAS and SSRS projects.  These must be done using Build-BiSolution below.
		#>	
		try {
			Write-Host "Building solution $SolutionName with MsBuild";
						
			$SolutionFolderPath = Get-SolutionPath($SolutionName);
			Write-Debug "Build-Solution path $SolutionFolderPath";
			
			assert(Test-Path $SolutionFolderPath) "Solution folder does not exist!";
			$logFilePath = "$TempPath\$SolutionName.log"
	
			exec { &"$MsBuildPath" "$SolutionFolderPath" /p:Configuration=$configuration /noconsolelogger /m /flp:"logfile=$logFilePath;errorsonly" }
		} catch {
			if (-not ([string]::IsNullOrEmpty($logFilePath))) {
				$msbuildlog = Get-Content($logFilePath);
				Write-Host $msbuildlog;
			}
			logError -Message "Build-Solution Failed to build solution $SolutionName Error: $_";
		}
	}	

	
	function Build-BiSolution ([string] $SolutionName = $(throw "Solution name required.") ) {
        <#
			.SYNOPSIS
			Builds a solution containing BI components (SSIS, SSRS and SSAS) using Visual Studio (devenv.exe).
			These components cannot be built using MsBuild.
			
			.NOTES
			We have to use Visual Studio devenv.exe to build a specific BI solution 
            For devenv.exe command-line options see https://msdn.microsoft.com/en-us/library/xee0c8y7.aspx 
		#>	
		try
		{
			Write-Host "Building solution $SolutionName with DevEnv.exe (Visual Studio)";
			
			$SolutionFolderPath = Get-SolutionPath($SolutionName);
			Write-Debug "Build-BiSolution path $SolutionFolderPath";

			$solutionNode = $deployConfig.DeploymentConfig.Solutions.Solution | where Name -EQ $SolutionName;
			assert(Test-Path($SolutionFolderPath)) "BI Solution file does not exist in $SolutionFolderPath";
			
			$logFilePath = "$TempPath\$solutionName.log"
				
			# As this is a windows EXE we need to wait for it to end before applying the scripts, so we pipe to Out-Null 
			exec { &"$VisualStudioPath" "$SolutionFolderPath" /build "$configuration" /out "$logFilePath" | Out-Null }
		} catch {
			logError -Message "Build-BiSolution Failed to build BI solution $SolutionName Error: $_";
		}        
    }

		
	function Build-SsasSolution ([string] $SolutionName = $(throw "Solution name required.") ) {
		<# 
			.SYNOPSIS 
			Builds a Visual Studio SSAS solution using MsBuild as outlined by Adam Gilmore in his post below. 
			However, does not work due to missing DLL
			Adam Gilmore post: http://www.dimodelo.com/blog/2014/automate-build-and-deployment-of-ssas-cubes-using-msbuild/
		#>	
		
		logError -Message "Build-SsasSolution DEPECREATED!";
		
		try {
			Write-Host "Building solution $SolutionName with MsBuild";
						
			$SolutionFolderPath = Get-SolutionPath($SolutionName);
			
			assert(Test-Path $SolutionFolderPath) "Solution folder does not exist!";
			$logFilePath = "$TempPath\$SolutionName.log"

			exec { &"$MsBuildPath" /target:BuildCube /property:solutionPath="$SolutionFolderPath" /p:Configuration="$configuration" }
		} catch {
			if (-not ([string]::IsNullOrEmpty($logFilePath))) {
				$msbuildlog = Get-Content($logFilePath);
				Write-Host $msbuildlog;
			}
			logError -Message "Build-SsasSolution Failed to build SSDT solution $SolutionName $_";
		}
	}
	