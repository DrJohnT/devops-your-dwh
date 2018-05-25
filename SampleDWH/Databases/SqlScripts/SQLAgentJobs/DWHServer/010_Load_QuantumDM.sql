use [msdb];
go

begin transaction;

declare @ReturnCode int = 0;
declare @JobName sysname = N'Load_QuantumDM';

/*
 * following SQLCmd variables used below
 $(SsisDbEnvironmentName)
 $(DWHServer)
 $(JobCategory)
 $(SsisDbProjectName)
 $(SsisDbFolderName)
 $(SsisProxyName)
 $(QuantumCubeServer)
 $(QDMOperatorName)
*/
declare @jobId binary(16);
declare @EnvRef int;
declare @commandStep1 nvarchar(500);
declare @commandStep2 nvarchar(500);

declare @ssasServer nvarchar(100) = lower(N'$(QuantumCubeServer)');
declare @dwhServer nvarchar(100) = lower(N'$(DWHServer)');
DECLARE @QDMOperatorName sysname = N'$(QDMOperatorName)';

if (CHARINDEX(@dwhServer, @ssasServer) = 1)
begin
	if (CHARINDEX('\', @ssasServer) > 1)
		select @ssasServer = REPLACE(@ssasServer, @dwhServer, N'localhost');
	else 
		select @ssasServer = N'localhost';
end

select
            @EnvRef = reference_id
from        SSISDB.[catalog].environment_references er
    join    SSISDB.[catalog].projects               p
      on    p.project_id = er.project_id
where
            er.environment_name = N'$(SsisDbEnvironmentName)'
            and p.[name] = N'$(SsisDbProjectName)';

set @commandStep1 = N'/ISSERVER "\"\SSISDB\$(SsisDbFolderName)\$(SsisDbProjectName)\MasterPackage.dtsx\"" /SERVER "\"$(DWHServer)\"" /ENVREFERENCE '
                    + CAST(@EnvRef as nvarchar(10))
                    + ' /Par "\"$ServerOption::LOGGING_LEVEL(Int16)\"";1 /Par "\"$ServerOption::SYNCHRONIZED(Boolean)\"";True /CALLERINFO SQLAGENT /REPORTING E';

if exists (
              select
                    job_id
              from  msdb.dbo.sysjobs_view
              where [name] = @JobName
          )
    exec msdb.dbo.sp_delete_job
        @job_name = @JobName,
        @delete_unused_schedule = 1;

exec @ReturnCode = msdb.dbo.sp_add_job
    @job_name = @JobName,
    @enabled = 1,
    @notify_level_eventlog = 0,
    @notify_level_email = 2,
    @notify_level_netsend = 0,
    @notify_level_page = 0,
    @delete_level = 0,
    @description = N'Load Staging, QuantumDM and Process QuantumCube',
    @category_name = N'$(JobCategory)',
    @owner_login_name = N'sa',
	@notify_email_operator_name=@QDMOperatorName,
    @job_id = @jobId output;

if (@@error <> 0 or @ReturnCode <> 0)
    goto QuitWithRollback;

exec @ReturnCode = msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = N'Run Master Package',
    @step_id = 1,
    @cmdexec_success_code = 0,
    @on_success_action = 3,
    @on_success_step_id = 0,
    @on_fail_action = 2,
    @on_fail_step_id = 0,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'SSIS',
    @command = @commandStep1,
    @database_name = N'master',
    @flags = 0,
    @proxy_name = N'$(SsisProxyName)';

if (@@error <> 0 or @ReturnCode <> 0)
    goto QuitWithRollback;

exec @ReturnCode = msdb.dbo.sp_add_jobstep
    @job_id = @jobId,
    @step_name = N'Process Tabular Cube - Full Process',
    @step_id = 2,
    @cmdexec_success_code = 0,
    @on_success_action = 1,
    @on_success_step_id = 0,
    @on_fail_action = 2,
    @on_fail_step_id = 0,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'ANALYSISCOMMAND',
    @command = N'{
  "refresh": {
    "type": "full",
    "objects": [
      {
        "database": "$(QuantumCube)"
      }
    ]
  }
}',
    @server = @ssasServer,
    @database_name = N'master',
    @flags = 0,
    @proxy_name = N'$(SsasProxyName)';

if (@@error <> 0 or @ReturnCode <> 0)
    goto QuitWithRollback;

exec @ReturnCode = msdb.dbo.sp_update_job
    @job_id = @jobId,
    @start_step_id = 1;

if (@@error <> 0 or @ReturnCode <> 0)
    goto QuitWithRollback;

exec @ReturnCode = msdb.dbo.sp_add_jobserver
    @job_id = @jobId,
    @server_name = N'(local)';

if (@@error <> 0 or @ReturnCode <> 0)
    goto QuitWithRollback;

commit transaction;

goto EndSave;

QuitWithRollback:
if (@@tranCount > 0)
    rollback transaction;

EndSave:
go