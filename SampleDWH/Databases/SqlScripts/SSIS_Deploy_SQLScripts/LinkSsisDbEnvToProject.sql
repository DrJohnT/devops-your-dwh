declare @project_name nvarchar(128) = N'$(SsisDbProjectName)';
declare @folder_name nvarchar(128) = N'$(SsisDbFolderName)';  
declare @environment_name nvarchar(128) = N'$(SsisDbEnvironmentName)';  

-- With gratitued to https://www.hansmichiels.com/2016/11/04/how-to-automate-your-ssis-package-deployment-and-configuration-ssis-series/

--\
---) Table variable to store selected project names.
--/
DECLARE @project_names_table TABLE(
  [id] int identity(1, 1),
  [project_name] NVARCHAR(128)
  )

--\
---) Table variable to store mappings between parameters and environment variables.
--/
DECLARE @object_parameter_value_table TABLE(
  [id] int identity(1, 1),
  [object_type] smallint,
  [object_name] nvarchar(260),
  [parameter_name] nvarchar(128),
  [project_name] NVARCHAR(128)
  )
  
DECLARE @message nvarchar(255)

DECLARE @id int
DECLARE @max_id int
DECLARE @object_type SMALLINT
DECLARE @object_name NVARCHAR(260)
DECLARE @value_type CHAR(1)
DECLARE @parameter_name NVARCHAR(128)
DECLARE @parameter_value SQL_VARIANT

DECLARE @reference_id BIGINT

--\
---) Environment settings
--/

INSERT INTO @project_names_table([project_name])
  SELECT 
      p.[name]
  FROM 
      [SSISDB].[internal].[folders] f
  JOIN 
      [SSISDB].[internal].[environments] e
      ON e.folder_id = f.folder_id
  JOIN 
      [SSISDB].[internal].[projects] p
      ON p.folder_id = f.folder_id
  WHERE 
      f.[name] = @folder_name
      AND e.environment_name = @environment_name
      AND p.[name] = @project_name;


--\
---) Add environment reference to project(s).
--/
SELECT @id = 1, @max_id = MAX([id]) FROM @project_names_table

WHILE (@id <= @max_id)
BEGIN
    SELECT 
      @project_name = v.[project_name]
    FROM @project_names_table v
    WHERE [id] = @id;

    IF NOT EXISTS( SELECT 1
        FROM 
            [SSISDB].[internal].[folders] f
        JOIN 
            [SSISDB].[internal].[environments] e
            ON e.folder_id = f.folder_id
        JOIN 
            [SSISDB].[internal].[projects] p
            ON p.folder_id = f.folder_id
        JOIN
            [SSISDB].[internal].[environment_references] r
            ON r.environment_name = e.environment_name
            AND p.project_id = r.project_id
        WHERE 
            f.[name] = @folder_name
            AND e.environment_name = @environment_name
            AND p.[name] = @project_name
        )  
    BEGIN
        SET @message = 'An environment reference for project "' + @project_name + '" is being created.'
        RAISERROR(@message , 0, 1) WITH NOWAIT;

        EXEC [SSISDB].[catalog].[create_environment_reference] 
            @environment_name=@environment_name, @reference_id=@reference_id OUTPUT, 
            @project_name=@project_name, @folder_name=@folder_name, @reference_type='R';
        --Select @reference_id
    END

    SET @id = @id + 1
END


--\
---) Connect environment variables to project parameters and 
---) package parameters, based on the name.
--/
INSERT INTO @object_parameter_value_table (
    [object_type],
    [object_name],
    [parameter_name],
    [project_name]
    )  
SELECT 
    prm.[object_type],
    prm.[object_name],
    prm.[parameter_name],
    prj.[name] 
FROM 
    [SSISDB].[internal].[folders] f
JOIN 
    [SSISDB].[internal].[environments] e
    ON e.folder_id = f.folder_id
JOIN 
    [SSISDB].[internal].[environment_variables] ev
    ON e.environment_id = ev.environment_id
JOIN 
    [SSISDB].[internal].[projects] prj
    ON prj.folder_id = f.folder_id
JOIN 
    @project_names_table prjsel
    ON prjsel.project_name = prj.[name] COLLATE Latin1_General_CI_AS
JOIN 
    [SSISDB].[internal].[object_parameters] prm
    ON prj.project_id = prm.project_id
    AND prm.parameter_name = ev.[name]
WHERE
    prm.[value_type] != 'R'
    AND prm.value_set = 0
    AND prm.[parameter_name] NOT LIKE 'CM.%'
    AND LEFT(prm.[parameter_name], 1) != '_' -- Naming convention for internally used parameters: start with _
    AND NOT ( prm.[object_type] = 30 AND LEFT(prm.[object_name], 1) = '_') -- Naming convention for internally used SSIS Packages: start with _
    AND f.[name] = @folder_name
    AND e.environment_name = @environment_name
ORDER BY 
    prm.object_name, prm.parameter_name

SELECT @id = 1, @max_id = MAX([id]) FROM @object_parameter_value_table
WHILE @id <= @max_id
BEGIN
    SELECT 
        @object_type = v.[object_type],
        @object_name = v.[object_name],
        @parameter_name = v.[parameter_name],
        @project_name = v.[project_name]
    FROM 
        @object_parameter_value_table v
    WHERE 
        [id] = @id;

    SELECT @value_type = 'R', @parameter_value = @parameter_name;
    
    SET @message = 'Parameter "' + @parameter_name + '" (of object "' + @object_name + '")  is mapped to environment variable.'
    RAISERROR(@message , 0, 1) WITH NOWAIT;

    EXEC [SSISDB].[catalog].[set_object_parameter_value] 
      @object_type, @folder_name, @project_name, @parameter_name, 
      @parameter_value, @object_name, @value_type

    SET @id = @id + 1
END


RAISERROR('Adding environment reference to project(s) and mapping environment variables to package parameters has completed.', 0, 1) WITH NOWAIT;

Finally:

GO