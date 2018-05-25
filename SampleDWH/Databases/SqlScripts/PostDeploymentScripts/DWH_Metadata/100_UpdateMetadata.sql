declare @environmentGroup nvarchar(20);

select
    @environmentGroup = '$(EnvironmentGroup)';

merge Metadata.DatabaseInfo as T
using
(
    select
        DatabaseInfoId,
        DatabaseName,
        ServerName,
        DatabaseGroup
    from
        (
            values (8, '$(DWH_Staging)', '$(DWH_StagingServer)', @environmentGroup),
                   (15, '$(DWH_QuantumDM)', '$(DWH_QuantumDMServer)', @environmentGroup)
        ) as V (DatabaseInfoId, DatabaseName, ServerName, DatabaseGroup)
) as S
on S.DatabaseInfoId = T.DatabaseInfoId
when matched then update set
                      DatabaseName = S.DatabaseName,
                      DatabaseGroup = S.DatabaseGroup,
                      ServerName = S.ServerName;


-- PREPROD should connect to Quantum PREPROD, so update metadata
-- Also, pre-prod cannot connect to PROD
if (@environmentGroup = 'PREPROD')
begin
    merge Metadata.DatabaseInfo as T
    using
    (
        select
            DatabaseInfoId,
            ServerName
        from
            (
                values (7, 'SZRHSQLCL01PRE'),
                       (14, 'SZRHSQLCL01PRE'),
					   (1,'SZRH5110'),
					   (2,'SZRH5110'),
					   (3,'SZRH5110'),
					   (4,'SZRH5110'),
					   (5,'SZRH5110'),
					   (9,'SZRH5110\qel'),
					   (10,'SZRH5110\qel'),
					   (11,'SZRH5110\qel'),
					   (12,'SZRH5110\qel'),
					   (13,'SZRH5110\qel')
            ) as V (DatabaseInfoId, ServerName)
    ) as S
    on S.DatabaseInfoId = T.DatabaseInfoId
    when matched then update set
                          ServerName = S.ServerName;
end;