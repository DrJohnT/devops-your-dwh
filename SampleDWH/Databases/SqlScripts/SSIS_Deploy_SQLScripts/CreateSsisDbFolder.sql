-- SQLCmd Script to create the ERS folder
declare @project_name nvarchar(128) = N'$(SsisDbProjectName)';
declare @folder_name nvarchar(128) = N'$(SsisDbFolderName)';
declare @folder_description nvarchar(255) = N'$(SsisDbFolderName) Project $(SsisDbProjectName) Release $(BuildNumber) Deployed by $(UserName)';

if not exists (
                  select
                        1
                  from  SSISDB.internal.folders
                  where [name] = @folder_name
              )
begin
    declare @folder_id bigint;

    exec SSISDB.[catalog].create_folder
        @folder_name = @folder_name,
        @folder_id = @folder_id output;

    -- update the folder's description so we capture the release number that originally created the folder
    update
            SSISDB.internal.folders
    set
            [description] = @folder_description
    where   [name] = @folder_name;
end;

-- provide svcSissDBreader-XXXX service account with permissions to execute the SSIS packages
declare @principal_id int;
declare @object_id bigint;

declare @serviceAccount sysname = N'cdxasd\dsadas-PROD';

select
        @principal_id = principal_id
from    SSISDB.sys.database_principals
where   [name] = @serviceAccount;

select
        @object_id = folder_id
from    SSISDB.internal.folders
where   [name] = @folder_name;

if (@principal_id is not null and   @object_id is not null)
begin
    exec SSISDB.[catalog].grant_permission
        @object_type = 1,       -- 1=folder
        @object_id = @object_id,
        @principal_id = @principal_id,
        @permission_type = 1;   -- 1=Read

    exec SSISDB.[catalog].grant_permission
        @object_type = 1,       -- 1=folder
        @object_id = @object_id,
        @principal_id = @principal_id,
        @permission_type = 101; -- 101=Read Objects

    exec SSISDB.[catalog].grant_permission
        @object_type = 1,       -- 1=folder
        @object_id = @object_id,
        @principal_id = @principal_id,
        @permission_type = 103; -- 103=Execute Objects
end;
