-- SQLCmd Script to create the ERS environment and add all the variables
declare @project_name nvarchar(128) = N'$(SsisDbProjectName)';
declare @folder_name nvarchar(128) = N'$(SsisDbFolderName)';  
declare @environment_name nvarchar(128) = N'$(SsisDbEnvironmentName)'; 
declare @environment_description nvarchar(128) = N'Config for $(SsisDbProjectName) Release $(BuildNumber) Deployed by $(UserName)';  

-- With gratitued to https://www.hansmichiels.com/2016/11/04/how-to-automate-your-ssis-package-deployment-and-configuration-ssis-series/

DECLARE @id int
DECLARE @max_id int
DECLARE @folder_id int
DECLARE @variable_name nvarchar(128)
DECLARE @data_type nvarchar(128)
DECLARE @sensitive bit
DECLARE @value sql_variant
DECLARE @description nvarchar(1024)
DECLARE @create_only bit -- 
DECLARE @exists bit
DECLARE @nsql nvarchar(max)
DECLARE @message nvarchar(255)

DECLARE @false BIT = 0, @true BIT = 1;

DECLARE @environment_variables_table TABLE(
  [id] int identity(1, 1),
  --)> Just an autonumber to be able to go through the table without cursor.
  [variable_name] nvarchar(128),
  --) Name of the variable  
  [data_type] nvarchar(128),
  --) Variable datatype e.g. [ Boolean | Byte | DateTime | Decimal | Double | Int16 | Int32 | Int64 | SByte | Single | String | UInt32 | UInt64 ]
  --) Check all possible values using this query: SELECT DISTINCT [ssis_data_type] FROM [SSISDB].[internal].[data_type_mapping]
  [sensitive] bit,
  --) Indication of the environment variable is sensitive (e.g. a password).
  [value] nvarchar(4000),
  --) The variable value.
  [description] nvarchar(1024),
  --) Extra description for the variable.
  [create_only] bit
  --) Indication that a variable should only be created when it does not exist yet, but should not be replaced when it already exists.
  --) (so the value in the script does not overwrite the existing value).
  --) In this way you can prevent later configuration changes in an environment being undone by the values in the script.
  )

IF NOT EXISTS ( 
    SELECT 1 
    FROM [SSISDB].[internal].[environments] e
		JOIN [SSISDB].[internal].[folders] f
			ON e.folder_id = f.folder_id
    WHERE e.[environment_name] = @environment_name 
        AND f.[name] = @folder_name
    )
BEGIN
    SET @message = 'Environment "' + @environment_name + '" is being created.'
    RAISERROR(@message , 0, 1) WITH NOWAIT;
    EXEC [SSISDB].[catalog].[create_environment] @folder_name, 
        @environment_name, @environment_description;
END

-- update the environment's description so we capture the release number
update SSISDB.internal.environments
	set [description]=@environment_description
where [environment_name] = @environment_name;

INSERT INTO @environment_variables_table 
      ( [create_only], [variable_name], [data_type], [sensitive], [value], [description] )
select 
	cast(0 as bit) as [create_only],
	REPLACE(DatabaseDescription,' ','') + N'_ConnectionString' as [variable_name],
	N'String' as [data_type],
	cast(0 as bit) as [sensitive],
	N'data source=' + ServerName + ';initial catalog=' + DatabaseName + ';provider=SQLNCLI11.1;integrated security=SSPI;' as [value], 
	DatabaseDescription + '_ConnectionString' as [description] 
from [$(DWH_Metadata)].Metadata.DatabaseInfo where DatabaseUseId in (select DatabaseUseId from [$(DWH_Metadata)].Metadata.DatabaseUse where DatabaseUse in ('SOURCE','TARGET','METADATA'));



--\
---) Loop through all parameters and create or replace them when needed.
--/
SELECT @id = 1, @max_id = MAX([id]) FROM @environment_variables_table
WHILE (@id <= @max_id)
BEGIN
    SELECT 
      @variable_name = v.variable_name,
      @data_type = v.data_type,
      @sensitive = v.sensitive,
      @value = v.value,
      @description = v.[description],
      @create_only = v.[create_only],
      @exists = 0
    FROM @environment_variables_table v
    WHERE [id] = @id;

    IF EXISTS (
        SELECT 1 
        FROM 
            [SSISDB].[internal].[environment_variables] v 
        JOIN
            [SSISDB].[internal].[environments] e ON e.environment_id = v.environment_id
        JOIN 
            [SSISDB].[internal].[folders] f
            ON e.folder_id = f.folder_id
        WHERE 
            v.[name] = @variable_name
            AND e.environment_name = @environment_name
            AND f.[name] = @folder_name
        )
    BEGIN
        IF (@create_only = 1)
        BEGIN
            SET @message = @variable_name + ' already exists and is not replaced.'
            RAISERROR(@message , 0, 1) WITH NOWAIT;
            SET @exists = 1;
        END 
		ELSE 
		BEGIN
            SET @message = 'Deleting variable "' + @variable_name + '" that will be replaced.';
            RAISERROR(@message , 0, 1) WITH NOWAIT;
            SET @nsql = N'EXECUTE [catalog].[delete_environment_variable] '
              + N'@folder_name = N'''+ @folder_name + ''', @environment_name = N''' + @environment_name + ''', '
              + N'@variable_name = N''' + @variable_name + ''''
            -- PRINT @nsql;
			SET @exists = 0;
            EXEC sp_executesql @nsql;
        END
    END 

    IF (@exists = 0)
    BEGIN
        SET @message = 'Creating variable "' + @variable_name + '".';
        RAISERROR(@message , 0, 1) WITH NOWAIT;

        SET @nsql = N'EXECUTE [catalog].[create_environment_variable] '
          + N'@folder_name = N'''+ @folder_name + ''', @environment_name = N''' + @environment_name + ''', '
          + N'@variable_name = N'''+ @variable_name + ''', @data_type = N''' + @data_type + ''', '
          + N'@sensitive = ' + CONVERT(NVARCHAR, @sensitive) + ', @description = N''' + @description + ''', '
          + CHAR(13) + CHAR(10) + N'@value = ' + 
          CASE UPPER(@data_type)
          WHEN 'String' THEN 'N''' + CONVERT(NVARCHAR(1000), @value) + ''' '
          ELSE CONVERT(NVARCHAR(1000), @value)
          END + '; '
        -- PRINT @nsql;
        EXEC sp_executesql @nsql;
    END
    SET @id = @id + 1
END

RAISERROR('Creating environment and variables has completed ..', 0, 1) WITH NOWAIT;
