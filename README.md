# Welcome to the devops-your-dwh project
This project provides PowerShell scripts which automate the build and deployment of a data warehouse.  The examples are written using the [**psake** build automation tool] (https://github.com/psake/psake) which is a convenient way of breaking your build into a series of tasks.

## How to get started

**Step 1:** Download and extract the project

You will need to "unblock" the zip file before extracting - PowerShell by default does not run files downloaded from the Internet.
Just right-click the zip and click on "properties" and click on the "unblock" button.

**Step 2:** Configure your PC
In order to use the PowerShell build scripts, you will need to install two PowerShell modules:
* [The **psake** build automation tool written in PowerShell] (https://www.powershellgallery.com/packages/psake/)
* [The **SqlServer** module provided by Microsoft] (https://www.powershellgallery.com/packages/SqlServer)

To check which modules you have installed, run
```
 Get-Module -ListAvailable
```
If you have a problem running the scripts, ensure you have unblocked the execution (described above) and open PowerShell in administrator mode and run:
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
Check your local execution policy using:
> Get-ExecutionPolicy -list


### Installing **psake** module
Like other PowerShell modules, **psake** is available on the PowerShell Gallery, so simply open PowerShell in administrator mode and use the following command to install: 
> Install-Module -Name psake

However, some corporate networks stop the installation of PowerShell modules using a group policy, in which case you can manually install **psake** by following the instructions provided on the [psake GitHub repository] (https://github.com/psake/psake)

### Installing **SqlServer** module
In 2016, Microsoft replaced the old SQLPS PowerShell module with the much improved [**SqlServer** PowerShell module] (https://blogs.technet.microsoft.com/dataplatforminsider/2016/06/30/sql-powershell-july-2016-update/).  However, as [various blogs] (http://www.mikefal.net/2016/07/12/out-with-the-sqlps-in-with-the-sqlserver/) point out, the old SQLPS module does not always play nicely with the new release, so it is best to completely remove SQLPS before installing the new **SqlServer** module.   To uninstall the old SQLPS module (if present) use:

> Uninstall-Module -Name SQLPS -Force 

We recommend using the following command to install the new **SqlServer** PowerShell module.
> Install-Module -Name SqlServer -AllowClobber -Force 	

Even after installation, if you find that PowerShell cannot find Invoke-SqlCmd or Invoke-AsCmd, then the SqlServer module has not installed correctly, so run the following commands which install a specific version of **SqlServer** module which we find always works.

> Uninstall-Module -Name SQLPS -Force 
> UnInstall-Module -Name SqlServer -Force
> Install-Module -Name SqlServer -AllowClobber -Force -RequiredVersion 21.0.17199  


## License

The devops-your-dwh project is released under the [MIT license](http://www.opensource.org/licenses/MIT).
Copyright 2016-2018 Dr. John Tunnicliffe
