-- From -- http://weblogs.sqlteam.com/peterl/archive/2008/11/27/Run-jobs-synchronously.aspx
--:setvar JobName "Load_QuantumDM"

declare
	@jobName sysname = N'$(JobName)',
    @jobID  uniqueidentifier,
    @maxID  int,
    @status int,
    @rc     int;

if (@jobName is null)
begin
    raiserror('Parameter @jobName have no value.', 16, 1);
end;

select
        @jobID = job_id
from    msdb.dbo.sysjobs
where   [name] = @jobName;

if @@error <> 0
begin
    raiserror('Error when returning jobID for job %s.', 18, 1, @jobName);
end;

if @jobID is null
begin
    raiserror('Job %s does not exist.', 16, 1, @jobName);
end;

select
        @maxID = MAX(instance_id)
from    msdb.dbo.sysjobhistory
where
        job_id = @jobID
        and step_id = 0;

if (@@error <> 0)
begin
    raiserror('Error when reading history for job %s.', 18, 1, @jobName);
end;

set @maxID = COALESCE(@maxID, -1);

exec @rc = msdb.dbo.sp_start_job @job_name = @jobName;

if (@@error <> 0 or @rc <> 0)
begin
    raiserror('Job %s did not start.', 18, 1, @jobName);
end;

while (
          select
                MAX(instance_id)
          from  msdb.dbo.sysjobhistory
          where
                job_id = @jobID
                and step_id = 0
      ) = @maxID
waitfor delay '00:00:01';

select
        @maxID = MAX(instance_id)
from    msdb.dbo.sysjobhistory
where
        job_id = @jobID
        and step_id = 0;

if (@@error <> 0)
begin
    raiserror('Error when reading history for job %s.', 18, 1, @jobName);
end;

select
        @status = run_status
from    msdb.dbo.sysjobhistory
where   instance_id = @maxID;

if (@@error <> 0)
begin
    raiserror('Error when reading status for job %s.', 18, 1, @jobName);
end;

if (@status <> 1)
begin
    raiserror('Job %s returned with an error.', 16, 1, @jobName);
end;
