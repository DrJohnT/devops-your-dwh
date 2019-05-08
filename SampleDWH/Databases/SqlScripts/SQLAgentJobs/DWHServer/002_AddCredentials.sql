/*
 * Adds the credentials for SQL Agent jobs to use to obtain data
 * Written by John Tunnicliffe, 2017
 */

BEGIN TRANSACTION

IF NOT EXISTS (select [name] from sys.credentials where [name] = N'$(SsisCredentialName)')
begin
	if (N'$(EnvironmentGroup)' = N'PREPROD')
		create CREDENTIAL [$(SsisCredentialName)] WITH IDENTITY = N'XXX\svcDBreader-PREP', SECRET = N'1234';
	else
		create CREDENTIAL [$(SsisCredentialName)] WITH IDENTITY = N'XXX\svcDBreader-PROD', SECRET = N'1234';

	IF (@@ERROR <> 0) GOTO QuitWithRollback
END

COMMIT TRANSACTION


BEGIN TRANSACTION
	IF NOT EXISTS (select [name] from sys.credentials where [name] = N'$(SsasCredentialName)')
	BEGIN
		if (N'$(EnvironmentGroup)' = N'DEV') -- covers DEVVM and BuildServer too
			CREATE CREDENTIAL [$(SsasCredentialName)] WITH IDENTITY = N'XXX\dev', SECRET = N'1234';
		if (N'$(EnvironmentGroup)' = N'TST')
			CREATE CREDENTIAL [$(SsasCredentialName)] WITH IDENTITY = N'XXX\pre', SECRET = N'1234';
		if (N'$(EnvironmentGroup)' = N'PREPROD')
			CREATE CREDENTIAL [$(SsasCredentialName)] WITH IDENTITY = N'XXX\pre', SECRET = N'1234';
		if (N'$(EnvironmentGroup)' = N'PROD')
			CREATE CREDENTIAL [$(SsasCredentialName)] WITH IDENTITY = N'XXX\prod', SECRET = N'1234';

		IF (@@ERROR <> 0) GOTO QuitWithRollback
	END


COMMIT TRANSACTION


GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:


GO



