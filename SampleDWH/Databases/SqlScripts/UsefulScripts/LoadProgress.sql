use DWH_QuantumDM;

declare @LoadLogId bigint;

select
        @LoadLogId = LoadLogId
from    Logging.LoadLog
where   LoadLogId = (
                        select  MAX(LoadLogId) from Logging.LoadLog
                    );

select
        *
from    Logging.LoadLog
where   LoadLogId = @LoadLogId;

exec Logging.LoadProgressReport @LoadLogId = @LoadLogId;

select
    @@serverName                   as database_name,
    event_message_id,
    CAST(message_time as datetime) as message_time,
    package_name,
    message_source_name,
    event_name,
    [message],
    operation_id,
    execution_path
from
    (
        select
                em.*,
                case
                    when message_type = 120 then 'Error'
                    when message_type = 110 then 'Warning'
                    when message_type = 70 then 'Info'
                    else 'Other'
                end as message_type_name
        from    SSISDB.catalog.event_messages em
        where
                em.operation_id = @LoadLogId
                and event_name not like '%Validate%'
                and message_type = 120 -- Error
    ) q
order by
    operation_id desc,
    event_message_id desc;

select
        DATEDIFF(s, MIN(LogDate), MAX(LogDate)) / 60.0 as TotalElapseMinutes
from    Logging.ProgressLog
where   LoadLogId = @LoadLogId;

select LoadLogId, MIN(LogDate) as StartTime,
        DATEDIFF(s, MIN(LogDate), MAX(LogDate)) / 60.0 as TotalElapseMinutes, 
		SUM(CountOfInsertedRows) as CountOfInsertedRows, SUM(CountOfUpdatedRows) as CountOfUpdatedRows
from    Logging.ProgressLog
where LoadLogId > -1
group by LoadLogId 
order by LoadLogId desc