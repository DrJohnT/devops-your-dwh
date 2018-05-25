/* 
 * Adds the Operators to manage notifications for jobs
 * Written by Adam Browne, April 2018
 */
DECLARE @ReturnCode INT;

/*
 * Main Operator for QDM
 */
BEGIN TRANSACTION

DECLARE @QDMOperatorName sysname = N'$(QDMOperatorName)';
DECLARE @QDMOperatorEmail sysname = N'$(QDMOperatorEmail)';


IF NOT EXISTS(select '1' from msdb..sysoperators where name = @QDMOperatorName)
EXEC msdb.dbo.sp_add_operator @name=@QDMOperatorName, 
		@enabled=1, 
		@weekday_pager_start_time=80000, 
		@weekday_pager_end_time=220000, 
		@saturday_pager_start_time=90000, 
		@saturday_pager_end_time=180000, 
		@sunday_pager_start_time=90000, 
		@sunday_pager_end_time=180000, 
		@pager_days=62, 
		@email_address=@QDMOperatorEmail, 
		@category_name=N'[Uncategorized]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

COMMIT TRANSACTION

GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:


GO



