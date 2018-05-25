/* 
 * Adds the Proxies to run jobs
 * Written by John Tunnicliffe, July 2017
 * See https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-grant-proxy-to-subsystem-transact-sql
 */
DECLARE @ReturnCode INT;

/*
 * Main proxy for SSIS = SsisProxyName
 */
BEGIN TRANSACTION

DECLARE @SsisCredentialName sysname = N'$(SsisCredentialName)';
DECLARE @SsisProxyName sysname = N'$(SsisProxyName)';

IF NOT EXISTS (select [name] from msdb.dbo.sysproxies where [name] = @SsisProxyName)
BEGIN
	EXEC msdb.dbo.sp_add_proxy @proxy_name=@SsisProxyName,@credential_name=@SsisCredentialName, @enabled=1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

	-- Operating System (CmdExec)
	EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=@SsisProxyName, @subsystem_id=3;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

	-- SSIS package execution
	EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=@SsisProxyName, @subsystem_id=11;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

	-- PowerShell script
	EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=@SsisProxyName, @subsystem_id=12;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

	
END

COMMIT TRANSACTION



/*
 * Proxy for SSAS cube processing = SsasProxyName
 */
BEGIN TRANSACTION

DECLARE @SsasCredentialName sysname = N'$(SsasCredentialName)';
DECLARE @SsasProxyName sysname = N'$(SsasProxyName)';

IF NOT EXISTS (select [name] from msdb.dbo.sysproxies where [name] = @SsasProxyName)
BEGIN
	EXEC msdb.dbo.sp_add_proxy @proxy_name=@SsasProxyName,@credential_name=@SsasCredentialName, @enabled=1
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

	-- Analysis Services Query
	EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=@SsasProxyName, @subsystem_id=9;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;

	-- Analysis Services Command
	EXEC msdb.dbo.sp_grant_proxy_to_subsystem @proxy_name=@SsasProxyName, @subsystem_id=10;
	IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback;
	
END

COMMIT TRANSACTION



GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:


GO



