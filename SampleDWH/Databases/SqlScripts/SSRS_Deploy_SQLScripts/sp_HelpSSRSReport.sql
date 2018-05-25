-- From https://gallery.technet.microsoft.com/scriptcenter/42440a6b-c5b1-4acc-9632-d608d1c40a5c
use ReportServer;

if OBJECT_ID('sp_HelpSSRSReport', 'P') is not null
    drop proc sp_HelpSSRSReport;
go

create proc sp_HelpSSRSReport
    @ReportName nvarchar(850),
    @ShowExecutionLog bit = 0
as
begin
    declare @Namespace nvarchar(500);
    declare @SQL varchar(max);

    select
        @Namespace = SUBSTRING(X.CatContent, X.CIndex, CHARINDEX('"', X.CatContent, X.CIndex + 7) - X.CIndex)
    from
        (
            select
                    CatContent = CONVERT(nvarchar(max), CONVERT(xml, CONVERT(varbinary(max), C.Content))),
                    CIndex     = CHARINDEX('xmlns="', CONVERT(nvarchar(max), CONVERT(xml, CONVERT(varbinary(max), C.Content))))
            from    dbo.[Catalog] C
            where
                    C.Content is not null
                    and C.Type = 2
        ) X;

    select
        @Namespace = REPLACE(@Namespace, 'xmlns="', '') + '';

    select
                Name,
                CreatedBy    = U.UserName,
                CreationDate = C.CreationDate,
                ModifiedBy   = UM.UserName,
                ModifiedDate
    from        dbo.[Catalog] C
        join    dbo.Users     U
          on    C.CreatedByID = U.UserID
        join    dbo.Users     UM
          on    C.ModifiedByID = UM.UserID
    where       Name = @ReportName;

    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    -- Get parameters of the report 
    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    select
                    Name          = Paravalue.value('Name[1]', 'VARCHAR(250)'),
                    Type          = Paravalue.value('Type[1]', 'VARCHAR(250)'),
                    Nullable      = Paravalue.value('Nullable[1]', 'VARCHAR(250)'),
                    AllowBlank    = Paravalue.value('AllowBlank[1]', 'VARCHAR(250)'),
                    MultiValue    = Paravalue.value('MultiValue[1]', 'VARCHAR(250)'),
                    UsedInQuery   = Paravalue.value('UsedInQuery[1]', 'VARCHAR(250)'),
                    Prompt        = Paravalue.value('Prompt[1]', 'VARCHAR(250)'),
                    DynamicPrompt = Paravalue.value('DynamicPrompt[1]', 'VARCHAR(250)'),
                    PromptUser    = Paravalue.value('PromptUser[1]', 'VARCHAR(250)'),
                    State         = Paravalue.value('State[1]', 'VARCHAR(250)')
    from
                    (
                        select
                                C.Name,
                                CONVERT(xml, C.Parameter) as ParameterXML
                        from    dbo.[Catalog] C
                        where
                                C.Content is not null
                                and C.Type = 2
                                and C.Name = @ReportName
                    )                                            a
        cross apply ParameterXML.nodes('//Parameters/Parameter') p(Paravalue);

    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    -- Get Datasources Associated with the report 
    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    select
        @SQL = 'WITH XMLNAMESPACES ( DEFAULT ''' + @Namespace
               + ''', ''http://schemas.microsoft.com/SQLServer/reporting/reportdesigner'' AS rd ) 
                SELECT  ReportName         = name 
                       ,DataSourceName     = x.value(''(@Name)[1]'', ''VARCHAR(250)'')  
                       ,DataProvider     = x.value(''(ConnectionProperties/DataProvider)[1]'',''VARCHAR(250)'') 
                       ,ConnectionString = x.value(''(ConnectionProperties/ConnectString)[1]'',''VARCHAR(250)'') 
                  FROM (  SELECT C.Name,CONVERT(XML,CONVERT(VARBINARY(MAX),C.Content)) AS reportXML 
                           FROM  dbo.[Catalog] C 
                          WHERE  C.Content is not null 
                            AND  C.Type  = 2 
                            AND  C.Name  = ''' + @ReportName
               + ''' 
                  ) a 
                  CROSS APPLY reportXML.nodes(''/Report/DataSources/DataSource'') r ( x ) 
                ORDER BY name ;';

    exec (@SQL);

    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    -- Get Data Sets , Command , Data fields Associated with the report 
    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    select
        @SQL = 'WITH XMLNAMESPACES ( DEFAULT ''' + @Namespace
               + ''', ''http://schemas.microsoft.com/SQLServer/reporting/reportdesigner'' AS rd ) 
SELECT  ReportName        = name 
       ,DataSetName        = x.value(''(@Name)[1]'', ''VARCHAR(250)'')  
       ,DataSourceName    = x.value(''(Query/DataSourceName)[1]'',''VARCHAR(250)'') 
       ,CommandText        = x.value(''(Query/CommandText)[1]'',''VARCHAR(250)'') 
       ,Fields            = df.value(''(@Name)[1]'',''VARCHAR(250)'') 
       ,DataField        = df.value(''(DataField)[1]'',''VARCHAR(250)'') 
       ,DataType        = df.value(''(rd:TypeName)[1]'',''VARCHAR(250)'') 
  FROM (  SELECT C.Name,CONVERT(XML,CONVERT(VARBINARY(MAX),C.Content)) AS reportXML 
           FROM  dbo.[Catalog] C 
          WHERE  C.Content is not null 
            AND  C.Type = 2 
            AND  C.Name = ''' + @ReportName
               + ''' 
       ) a 
  CROSS APPLY reportXML.nodes(''/Report/DataSets/DataSet'') r ( x ) 
  CROSS APPLY x.nodes(''Fields/Field'') f(df)  
ORDER BY name ';

    exec (@SQL);

    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    -- Get subscription Associated with the report 
    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    select
                Reportname        = c.Name,
                SubscriptionDesc  = su.Description,
                Subscriptiontype  = su.EventType,
                su.LastStatus,
                su.LastRunTime,
                Schedulename      = Sch.Name,
                ScheduleType      = Sch.EventType,
                ScheduleFrequency = case Sch.RecurrenceType
                                        when 1 then 'Once'
                                        when 2 then 'Hourly'
                                        when 4 then 'Daily/Weekly'
                                        when 5 then 'Monthly'
                                    end,
                su.Parameters
    from        dbo.Subscriptions  su
        join    dbo.[Catalog]      c
          on    su.Report_OID = c.ItemID
        join    dbo.ReportSchedule rsc
          on    rsc.ReportID = c.ItemID
                and rsc.SubscriptionID = su.SubscriptionID
        join    dbo.Schedule       Sch
          on    rsc.ScheduleID = Sch.ScheduleID
    where       c.Name = @ReportName;

    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    -- Get Snapshot associated with the report 
    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    select
                    c.Name,
                    H.SnapshotDate,
                    S.Description,
                    ScheduleForSnapshot = ISNULL(Sc.Name, 'No Schedule available for Snapshot'),
                    ScheduleType        = Sc.EventType,
                    ScheduleFrequency   = case Sc.RecurrenceType
                                              when 1 then 'Once'
                                              when 2 then 'Hourly'
                                              when 4 then 'Daily/Weekly'
                                              when 5 then 'Monthly'
                                          end,
                    Sc.LastRunTime,
                    Sc.LastRunStatus,
                    ScheduleNextRuntime = Sc.NextRunTime,
                    S.EffectiveParams,
                    S.QueryParams
    from            dbo.History        H
        join        dbo.SnapshotData   S
          on        H.SnapshotDataID = S.SnapshotDataID
        join        dbo.[Catalog]      c
          on        c.ItemID = H.ReportID
        left join   dbo.ReportSchedule Rs
          on        Rs.ReportID = H.ReportID
                    and Rs.ReportAction = 2
        left join   dbo.Schedule       Sc
          on        Sc.ScheduleID = Rs.ScheduleID
    where           c.Name = @ReportName;

    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    -- Get Users List having access to reports and tasks they can perform on the report 
    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    select
                c.Name,
                U.UserName,
                R.RoleName,
                R.Description,
                U.AuthType
    from        dbo.Users          U
        join    dbo.PolicyUserRole PUR
          on    U.UserID = PUR.UserID
        join    dbo.Policies       P
          on    P.PolicyID = PUR.PolicyID
        join    dbo.Roles          R
          on    R.RoleID = PUR.RoleID
        join    dbo.[Catalog]      c
          on    c.PolicyID = P.PolicyID
    where       c.Name = @ReportName
    order by    U.UserName;

    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    -- Execution Log fo the report 
    ---------------------------------------------------------------------------------------------------------------------------------------------------------- 
    if (@ShowExecutionLog = 1)
        select
                    C.Name,
                    case E.RequestType
                        when 1 then 'Subscription'
                        when 0 then 'Report Launch'
                        else ''
                    end,
                    E.TimeStart,
                    E.TimeProcessing,
                    E.TimeRendering,
                    E.TimeEnd,
                    E.Status,
                    E.InstanceName,
                    E.UserName
        from        dbo.ExecutionLog E
            join    dbo.[Catalog]    C
              on    E.ReportID = C.ItemID
        where       C.Name = @ReportName
        order by    E.TimeStart desc;
end;

-- EXEC sp_HelpSSRSReport @ReportName = 'Policy Technical Transactions', @ShowExecutionLog=1
/*

select
            [Name]                                                                               as ReportName,
            [Path]                                                                               as FullPath,
            REVERSE(SUBSTRING(REVERSE(Path), CHARINDEX('/', REVERSE(Path)), LEN(REVERSE(Path)))) as ReportFolderPath,
            [Description]
from        [dbo].[Catalog]
where       [Type] = 2
order by    [Path];

*/