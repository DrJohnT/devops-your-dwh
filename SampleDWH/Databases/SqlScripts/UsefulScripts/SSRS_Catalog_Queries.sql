use ReportServer;

select
            [Name]                                                                               as ReportName,
            [Path]                                                                               as FullPath,
            REVERSE(SUBSTRING(REVERSE(Path), CHARINDEX('/', REVERSE(Path)), LEN(REVERSE(Path)))) as ReportFolderPath,
            [Description]
from        [dbo].[Catalog]
where       [Type] = 2
order by    [Path];

-- EXEC sp_HelpSSRSReport @ReportName = 'Policy Booking Details', @ShowExecutionLog=1

SELECT * FROM dbo.[Catalog]
SELECT * from dbo.[DataSets]
SELECT * FROM dbo.[DataSource]
SELECT * FROM dbo.[Users]

-- Columns described on http://www.sqlgirl.com/blog/2012/09/20/report-server-executionlog-ssrs/
-- See https://docs.microsoft.com/en-us/sql/reporting-services/report-server/report-server-executionlog-and-the-executionlog3-view
SELECT top 10000 * FROM dbo.ExecutionLog3 order by  TimeStart DESC

SELECT top 10000 * FROM dbo.ExecutionLog3 where RequestType = 'Interactive'
 order by  TimeStart DESC

select
            C.[Name]                                                                             as ReportName,
            UserName,
            --[Path]                                                                               as FullPath,
            REVERSE(SUBSTRING(REVERSE(Path), CHARINDEX('/', REVERSE(Path)), LEN(REVERSE(Path)))) as ReportFolderPath,
            COUNT(*)                                                                             as CountOfExecutions,
            MAX(E.TimeStart)                                                                     as LastUsedDate
from        dbo.ExecutionLog E
    join    dbo.[Catalog]    C
      on    E.ReportID = C.ItemID
where
            RequestType = 0 -- 'Report Launch'
            and E.TimeStart > DATEADD(month, -6, GETDATE())
group by
            C.[Name],
            [Path],
            UserName
order by
            C.[Name],
            UserName;

select
            C.[Name]                                                                             as ReportName,
            --[Path]                                                                               as FullPath,
            REVERSE(SUBSTRING(REVERSE(Path), CHARINDEX('/', REVERSE(Path)), LEN(REVERSE(Path)))) as ReportFolderPath,
            COUNT(*)                                                                             as CountOfExecutions,
            MAX(E.TimeStart)                                                                     as LastUsedDate
from        dbo.ExecutionLog E
    join    dbo.[Catalog]    C
      on    E.ReportID = C.ItemID
where
            RequestType = 0 -- 'Report Launch'
            and E.TimeStart > DATEADD(month, -6, GETDATE())
group by
            C.[Name],
            [Path]
order by
	--4 desc,
            3 desc,
            1;
