
declare @JobName sysname = N'Load_QuantumDM';

-- delete the job 
IF EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE [name] = @JobName)
	EXEC msdb.dbo.sp_delete_job @job_name=@JobName, @delete_unused_schedule=1;

