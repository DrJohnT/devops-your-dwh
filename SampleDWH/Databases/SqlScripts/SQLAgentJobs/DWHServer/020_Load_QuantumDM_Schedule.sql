declare
    @jobName    sysname         = N'Load_QuantumDM',
    @jobID      uniqueidentifier,
    @ReturnCode int             = 0;

select
        @jobID = job_id
from    msdb.dbo.sysjobs
where   [name] = @jobName;

if (N'$(EnvironmentName)' = N'PROD')
begin
    begin transaction;

	-- 10 minutes past the hour
    exec @ReturnCode = msdb.dbo.sp_add_jobschedule
        @job_id = @jobID,
        @name = N'Hourly',
        @enabled = 1,
        @freq_type = 4,
        @freq_interval = 1,
        @freq_subday_type = 8,
        @freq_subday_interval = 1,
        @freq_relative_interval = 0,
        @freq_recurrence_factor = 0,
        @active_start_date = 20180222,
        @active_end_date = 99991231,
        @active_start_time = 1000,
        @active_end_time = 235959,
        @schedule_uid = N'c861291c-2b0f-446b-955e-4337684487b2';

    if (@@error <> 0 or @ReturnCode <> 0)
        goto QuitWithRollback;

    commit transaction;
end;

if (N'$(EnvironmentName)' = N'TST')
begin
    begin transaction;

	-- 20 minutes past the hour
    exec @ReturnCode = msdb.dbo.sp_add_jobschedule
        @job_id = @jobID,
        @name = N'Hourly on TST',
        @enabled = 1,
        @freq_type = 4,
        @freq_interval = 1,
        @freq_subday_type = 8,
        @freq_subday_interval = 1,
        @freq_relative_interval = 0,
        @freq_recurrence_factor = 0,
        @active_start_date = 20180222,
        @active_end_date = 99991231,
		@active_start_time=2000, 
		@active_end_time=235959, 
        @schedule_uid = N'babd5d8c-8de3-4c81-b378-230bcade0964';

    if (@@error <> 0 or @ReturnCode <> 0)
        goto QuitWithRollback;

    commit transaction;
end;


if (N'$(EnvironmentName)' = N'PREPROD')
begin
    begin transaction;

	-- 20 minutes past the hour
    exec @ReturnCode = msdb.dbo.sp_add_jobschedule
        @job_id = @jobID,
        @name = N'Hourly on PREPROD',
        @enabled = 1,
        @freq_type = 4,
        @freq_interval = 1,
        @freq_subday_type = 8,
        @freq_subday_interval = 1,
        @freq_relative_interval = 0,
        @freq_recurrence_factor = 0,
        @active_start_date = 20180222,
        @active_end_date = 99991231,
		@active_start_time=3000, 
		@active_end_time=235959, 
        @schedule_uid = N'babd5d8c-8de3-4c81-b378-230bcade0964';

    if (@@error <> 0 or @ReturnCode <> 0)
        goto QuitWithRollback;

    commit transaction;
end;

goto EndSave;

QuitWithRollback:
if (@@tranCount > 0)
    rollback transaction;

EndSave:
go