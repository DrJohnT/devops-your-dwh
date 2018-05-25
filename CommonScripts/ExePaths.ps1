#####################################################################################################
# Script written by © Dr. John Tunnicliffe, 2015-2018 https://github.com/DrJohnT/devops-your-dwh
# This PowerShell script is released under the MIT license http://www.opensource.org/licenses/MIT
#
# Defines location of EXE Paths required for the build and deployment
# 
# As anyone will know, Microsoft keep changing the install location of each component for every 
# release.  This script attempts to find the latest version installed on your machine.
#####################################################################################################

    <# Note
		Visual Studio 2008 =  9.0
        Visual Studio 2010 = 10.0
        Visual Studio 2012 = 11.0
        Visual Studio 2013 = 12.0
        Visual Studio 2015 = 14.0 (yes, Microsoft are superstitious!)
        Visual Studio 2017 = 15.0

        SQL Server 2008 = 100
        SQL Server 2012 = 110
        SQL Server 2014 = 120
        SQL Server 2016 = 130
        SQL Server 2017 = 140
    #>

	# Nuget.exe path
	# if this is not found, then download nuget.exe from https://dist.nuget.org/index.html and copy manually to the following location:
	[string] $NugetPath = "${env:ProgramFiles(x86)}\Nuget\nuget.exe";
	

    # SqlPackage.exe for deploying SSDT DacPacs
	# See https://msdn.microsoft.com/en-us/library/hh550080.aspx
    [string] $SqlPackageExePath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\140\DAC\bin\SqlPackage.exe";
    if (!(Test-Path($SqlPackageExePath))) {
		$SqlPackageExePath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\130\DAC\bin\SqlPackage.exe";
	} 
    if (!(Test-Path($SqlPackageExePath))) {
		$SqlPackageExePath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\120\DAC\bin\SqlPackage.exe";
	} 
    if (!(Test-Path($SqlPackageExePath))) {
		$SqlPackageExePath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\DAC\bin\SqlPackage.exe";
	} 
	if (!(Test-Path($SqlPackageExePath))) {
	    $SqlPackageExePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\140\SqlPackage.exe";	
	}
	if (!(Test-Path($SqlPackageExePath))) {
	    $SqlPackageExePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\130\SqlPackage.exe";	
	}
	if (!(Test-Path($SqlPackageExePath))) {
	    $SqlPackageExePath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\Extensions\Microsoft\SQLDB\DAC\120\SqlPackage.exe";	
	}

	
    # IsDeploymentWizard.exe for deploying SSIS projects
	# See https://docs.microsoft.com/en-us/sql/integration-services/packages/deploy-integration-services-ssis-projects-and-packages
    [string] $SsisDeploymentWizard = "${env:ProgramFiles(x86)}\Microsoft SQL Server\140\DTS\binn\isdeploymentwizard.exe";
    if (!(Test-Path($SsisDeploymentWizard))) {
		$SsisDeploymentWizard = "${env:ProgramFiles(x86)}\Microsoft SQL Server\130\DTS\binn\isdeploymentwizard.exe";
	} 
    if (!(Test-Path($SsisDeploymentWizard))) {
		$SsisDeploymentWizard = "${env:ProgramFiles(x86)}\Microsoft SQL Server\120\DTS\binn\isdeploymentwizard.exe";
	} 
    if (!(Test-Path($SsisDeploymentWizard))) {
		$SsisDeploymentWizard = "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\DTS\binn\isdeploymentwizard.exe";
	} 


	# MsTest.exe for running tests
	[string] $MsTestPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Professional\Common7\IDE\MSTest.exe";
    if (!(Test-Path($MsTestPath))) {
		$MsTestPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\MSTest.exe";
	} 
    if (!(Test-Path($MsTestPath))) {
		$MsTestPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\MSTest.exe";
	} 
    if (!(Test-Path($MsTestPath))) {
		$MsTestPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\IDE\MSTest.exe";
	} 
    if (!(Test-Path($MsTestPath))) {
		$MsTestPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 10.0\Common7\IDE\MSTest.exe";
	} 

	
	# VSTS TF command path for running VSTS commands
	[string] $TfPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe";
    if (!(Test-Path($TfPath))) {
		$TfPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\TF.exe";
	}
    if (!(Test-Path($TfPath))) {
		$TfPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\TF.exe";
	} 
    if (!(Test-Path($TfPath))) {
		$TfPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\IDE\TF.exe";
	} 
    if (!(Test-Path($TfPath))) {
		$TfPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 10.0\Common7\IDE\TF.exe";
	} 

	
	# MSBuild path for building C# and SSDT projects
	#[string] $MsBuildPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MsBuild.exe";
    #if (!(Test-Path($MsBuildPath))) {
		$MsBuildPath = "${env:ProgramFiles(x86)}\MSBuild\14.0\Bin\MsBuild.exe";
	#} 
    if (!(Test-Path($MsBuildPath))) {
		$MsBuildPath = "${env:ProgramFiles(x86)}\MSBuild\12.0\Bin\MsBuild.exe";
	} 
	

	# devenv.exe for building Visual Studio solutions that contain BI components such as SSRS, SSIS and SSAS
	# Visual Studio 15 2017
	#[string] $VisualStudioPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Professional\Common7\IDE\devenv.exe";
    #if (!(Test-Path($VisualStudioPath))) {
        # Visual Studio 14 2015
		$VisualStudioPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 14.0\Common7\IDE\devenv.exe";
	#} 
    if (!(Test-Path($VisualStudioPath))) {
        # Visual Studio 12 2013
		$VisualStudioPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 12.0\Common7\IDE\devenv.exe";
	} 
    if (!(Test-Path($VisualStudioPath))) {
        # Visual Studio 11 2012
		$VisualStudioPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 11.0\Common7\IDE\devenv.exe";
	} 
    if (!(Test-Path($VisualStudioPath))) {
        # Visual Studio 10 2010
		$VisualStudioPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 10.0\Common7\IDE\devenv.exe";
	} 
    if (!(Test-Path($VisualStudioPath))) {
        # Visual Studio 9  2008
		$VisualStudioPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio 9.0\Common7\IDE\devenv.exe";
	} 
	
	
	# Microsoft.AnalysisServices.Deployment.exe for deploying Analysis Services databases (both Tabular and OLAP)
    [string] $SsasDeployWizardPath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\140\Tools\Binn\ManagementStudio\Microsoft.AnalysisServices.Deployment.exe";
    if (!(Test-Path($SsasDeployWizardPath))) {
		$SsasDeployWizardPath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\120\Tools\Binn\ManagementStudio\Microsoft.AnalysisServices.Deployment.exe";
	} 
    if (!(Test-Path($SsasDeployWizardPath))) {
		$SsasDeployWizardPath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\Tools\Binn\ManagementStudio\Microsoft.AnalysisServices.Deployment.exe";
	}
    if (!(Test-Path($SsasDeployWizardPath))) {
		$SsasDeployWizardPath = "${env:ProgramFiles(x86)}\Microsoft SQL Server\100\Tools\Binn\VSShell\Common7\IDE\Microsoft.AnalysisServices.Deployment.exe";
	} 
	
	
	# rs.exe Reporting Services Utility 
	[string] $SsrsDeploymentUtility = "${env:ProgramFiles(x86)}\Microsoft SQL Server\140\Tools\Binn\rs.exe";
    if (!(Test-Path($SsrsDeploymentUtility))) {
		$SsrsDeploymentUtility = "${env:ProgramFiles(x86)}\Microsoft SQL Server\120\Tools\Binn\rs.exe";
	} 
    if (!(Test-Path($SsrsDeploymentUtility))) {
		$SsrsDeploymentUtility = "${env:ProgramFiles(x86)}\Microsoft SQL Server\110\Tools\Binn\rs.exe";
	}
    if (!(Test-Path($SsrsDeploymentUtility))) {
		$SsrsDeploymentUtility = "${env:ProgramFiles(x86)}\Microsoft SQL Server\100\Tools\Binn\rs.exe";
	} 
	
	
    # bcp.exe 64-bit for bulk copy loading test data
    [string] $BcpPath ="${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\140\Tools\Binn\bcp.exe"
    if (!(Test-Path($BcpPath))) {
        $BcpPath ="${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\bcp.exe"
    }
    if (!(Test-Path($BcpPath))) {
        $BcpPath ="${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\120\Tools\Binn\bcp.exe"
    }
    if (!(Test-Path($BcpPath))) {
        $BcpPath ="${env:ProgramFiles}\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\bcp.exe"
    }
	
	
	# bcp.exe 32-bit for bulk copy loading test data
	[string] $BcpPath32 ="${env:ProgramFiles(x86)}\Microsoft SQL Server\Client SDK\ODBC\140\Tools\Binn\bcp.exe"
    if (!(Test-Path($BcpPath32))) {
        $BcpPath32 ="${env:ProgramFiles(x86)}\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn\bcp.exe"
    }
    if (!(Test-Path($BcpPath32))) {
        $BcpPath32 ="${env:ProgramFiles(x86)}\Microsoft SQL Server\Client SDK\ODBC\120\Tools\Binn\bcp.exe"
    }
    if (!(Test-Path($BcpPath32))) {
        $BcpPath32 ="${env:ProgramFiles(x86)}\Microsoft SQL Server\Client SDK\ODBC\110\Tools\Binn\bcp.exe"
    }


	function DisplayExePaths {
		# Displays the paths to all the EXE files

		Write-Host;
		if (Test-Path($VisualStudioPath)) {
			Write-Host "DevEnv.exe (Visual Studio) exists. Path: $VisualStudioPath";
		} else {
			Write-Host "DevEnv.exe (Visual Studio) does NOT exist in path = $VisualStudioPath" -ForegroundColor Red; 
		}
		
		Write-Host;
		if (Test-Path($MsBuildPath)) {
			Write-Host "MsBuild.exe exists. Path: $MsBuildPath";
		} else {
			Write-Host "MsBuild.exe does NOT exist in path = $MsBuildPath" -ForegroundColor Red; 
		}

		Write-Host;
		if (Test-Path($SqlPackageExePath)) {
			Write-Host "SqlPackage.exe exists. Path: $SqlPackageExePath";
		} else {
			Write-Host "SqlPackage.exe NOT found in location $SqlPackageExePath" -ForegroundColor Red; 
		}
		
		Write-Host;
		if (Test-Path($MsTestPath)) {
			Write-Host "MsTest exists. Path: $MsTestPath";
		} else {
			Write-Host "MsTest NOT found in location $MsTestPath" -ForegroundColor Red; 
		}
		
		Write-Host;
		if (Test-Path($SsasDeployWizardPath)) {
			Write-Host "Microsoft.AnalysisServices.Deployment.exe exists. Path: $SsasDeployWizardPath";
		} else {
			Write-Host "Microsoft.AnalysisServices.Deployment.exe not found in location $SsasDeployWizardPath" -ForegroundColor Red; 
		}

		Write-Host;
		if (Test-Path($SsisDeploymentWizard)) {
			Write-Host "isdeploymentwizard.exe exists. Path: $SsisDeploymentWizard";
		} else {
			Write-Host "isdeploymentwizard.exe not found in location $SsisDeploymentWizard" -ForegroundColor Red; 
		}

		Write-Host;
		if (Test-Path($SsrsDeploymentUtility)) {
			Write-Host "rs.exe exists. Path: $SsrsDeploymentUtility";
		} else {
			Write-Host "rs.exe not found in location $SsrsDeploymentUtility" -ForegroundColor Red; 
		}
		
		Write-Host;
        if (Test-Path($BcpPath)) {
			Write-Host "bcp.exe 64-bit exists. Path: $BcpPath";
		} else {
			Write-Host "bcp.exe 64-bit not found in location $BcpPath" -ForegroundColor Red; 
		}
		
		Write-Host;
        if (Test-Path($BcpPath32)) {
			Write-Host "bcp.exe 32-bit exists. Path: $BcpPath32";
		} else {
			Write-Host "bcp.exe 32-bit not found in location $BcpPath32" -ForegroundColor Red; 
		}
				
		Write-Host;				
		if (Test-Path($NugetPath)) {
			Write-Host "Nuget.exe exists. Path: $NugetPath";
		} else {
			Write-Host "Nuget.exe not found in location $NugetPath" -ForegroundColor Red; 
		}
		
		Write-Host;
		if (Test-Path($TfPath)) {
			Write-Host "TFS TF.exe exists. Path: $TfPath";
		} else {
			Write-Host "TFS TF.exe not found in location $TfPath" -ForegroundColor Red; 
		}
	}