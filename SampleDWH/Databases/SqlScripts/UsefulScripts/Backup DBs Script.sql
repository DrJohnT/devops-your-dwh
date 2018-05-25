DECLARE @DBName VARCHAR(100)				-- database name  
DECLARE @BackupPath VARCHAR(256) = '\\SZRH2000\SQLBackup\' + @@SERVERNAME + '\'
DECLARE @fileName VARCHAR(256)			-- filename for backup  

--Cycle variables
DECLARE @i int = 1							
DECLARE @DBNames TABLE ( idx int Primary Key IDENTITY(1,1), DBName VARCHAR(100))

INSERT @DBNames
SELECT name FROM master.dbo.sysdatabases 
WHERE name NOT IN ('master','model','msdb','tempdb','ReportServer','ReportServerTempDB','SSISDB')  -- exclude these databases

IF (SELECT COUNT(*) FROM @DBNames) > 0
WHILE (@i <= (SELECT MAX(idx) FROM @DBNames))
BEGIN
    SET @DBName = (SELECT DBName FROM @DBNames WHERE idx = @i)
        
	SET @fileName = @BackupPath + @DBName + '_' + CONVERT(VARCHAR(20),GETDATE(),112) + '.BAK'  
	
	--Backup DBs
	BACKUP DATABASE @DBName TO DISK = @fileName  		
	
	--Truncate Logs
	EXEC ('USE ' + @DBName + '; DBCC SHRINKFILE ( ' + @DBName + '_Log, 1);'); 

    SET @i = @i + 1

END

