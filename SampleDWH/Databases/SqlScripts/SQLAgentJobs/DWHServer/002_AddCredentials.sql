/* 
 * Adds the credentials for SQL Agent jobs to use to obtain data
 * Written by John Tunnicliffe, 2017
 */

BEGIN TRANSACTION

IF NOT EXISTS (select [name] from sys.credentials where [name] = N'$(SsisCredentialName)')
begin
	if (N'$(EnvironmentGroup)' = N'PREPROD')
		create CREDENTIAL [$(SsisCredentialName)] WITH IDENTITY = N'qregroup\svcSissDBreader-PREP', SECRET = N'D5JBv5SySJ';
	else
		create CREDENTIAL [$(SsisCredentialName)] WITH IDENTITY = N'qregroup\svcSissDBreader-PROD', SECRET = N'W1PsiQkrud';

	IF (@@ERROR <> 0) GOTO QuitWithRollback
END

COMMIT TRANSACTION


BEGIN TRANSACTION
	IF NOT EXISTS (select [name] from sys.credentials where [name] = N'$(SsasCredentialName)')
	BEGIN
		if (N'$(EnvironmentGroup)' = N'DEV') -- covers DEVVM and BuildServer too
			CREATE CREDENTIAL [$(SsasCredentialName)] WITH IDENTITY = N'qregroup\qresvczrhsqldev', SECRET = N'RDZ$NAwNB1xF';
		if (N'$(EnvironmentGroup)' = N'TST') 
			CREATE CREDENTIAL [$(SsasCredentialName)] WITH IDENTITY = N'qregroup\qresvczrhsqlpre', SECRET = N'3MgFJ^YyXp7e';
		if (N'$(EnvironmentGroup)' = N'PREPROD')
			CREATE CREDENTIAL [$(SsasCredentialName)] WITH IDENTITY = N'qregroup\qresvczrhsqlpre', SECRET = N'3MgFJ^YyXp7e';
		if (N'$(EnvironmentGroup)' = N'PROD')
			CREATE CREDENTIAL [$(SsasCredentialName)] WITH IDENTITY = N'qregroup\qresvczrhsqlprod', SECRET = N'pOC5fO#DMVl0';

		IF (@@ERROR <> 0) GOTO QuitWithRollback
	END


COMMIT TRANSACTION


GOTO EndSave

QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:


GO



