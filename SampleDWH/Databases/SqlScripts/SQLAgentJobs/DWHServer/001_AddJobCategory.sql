/* 
 * Adds a specific job category to the server
 * Written by John Tunnicliffe, July 2017
 */
DECLARE @ReturnCode INT;

BEGIN TRANSACTION

DECLARE @CategoryName sysname = N'$(JobCategory)';

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=@CategoryName AND category_class=1)
BEGIN
	EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=@CategoryName
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
END

COMMIT TRANSACTION
GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:


GO



