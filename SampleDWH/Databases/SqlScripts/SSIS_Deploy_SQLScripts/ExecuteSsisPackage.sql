:setvar SsisDbProjectName "Load_DWH"
:setvar SsisDbFolderName "QRE_DWH"
:setvar SsisDbEnvironmentName "QRE"
:setvar SsisPackageName "MasterPackage"

-- Execute an SSIS package
declare @execution_id BIGINT, @EnvRef int;

SELECT  @EnvRef = reference_id
  FROM  [SSISDB].[catalog].environment_references er
        JOIN [SSISDB].[catalog].projects p ON p.project_id = er.project_id
 WHERE  er.environment_name =  N'$(SsisDbEnvironmentName)'
   AND  p.[name]            =  N'$(SsisDbProjectName)';

-- Get the @execution_id
EXEC [SSISDB].[catalog].[create_execution] 
	@package_name=N'$(SsisPackageName).dtsx'
	, @project_name=N'$(SsisDbProjectName)'
	, @folder_name=N'$(SsisDbFolderName)'
	, @use32bitruntime=False
	, @reference_id=@EnvRef
	, @execution_id=@execution_id OUTPUT;


-- wait for the package to execute
EXEC [SSISDB].[catalog].[set_execution_parameter_value] @execution_id, 
	@object_type=50, 
	@parameter_name=N'SYNCHRONIZED', 
	@parameter_value=1;
  
-- Execute the package
EXEC [SSISDB].[catalog].[start_execution] @execution_id=@execution_id;