
print '$(UserGroup)'
begin try
    if not exists (
                      select
                            [name]
                      from  sys.server_principals
                      where [name] = '$(UserGroup)'
                  )
    begin
        create login [$(UserGroup)] from windows
        with default_database = [master], default_language = [us_english];
		print 'Created login ''$(UserGroup)'' on server ' + @@serverName;
    end;

    if not exists (
                      select
                            [name]
                      from  sys.database_principals
                      where [name] = '$(UserGroup)'
                  )
    begin
        create user [$(UserGroup)] for login [$(UserGroup)]
        with
            default_schema = [$(DefaultSchemaName)];
		print 'Created User ''$(UserGroup)'' in database ' + DB_NAME(DB_ID());
    end;

    if not exists (
                      select
                                1
                      from      sys.database_role_members A
                          join  sys.database_principals   B
                            on  A.role_principal_id = B.principal_id
                          join  sys.database_principals   C
                            on  A.member_principal_id = C.principal_id
                      where
                                B.[name] = '$(RoleName)'
                                and C.[name] = '$(UserGroup)'
                  )
    begin
        alter role [$(RoleName)] add member [$(UserGroup)];
		print 'Added ''$(UserGroup)'' to role $(RoleName)';
    end;
end try
begin catch
    print 'Failed to add ''$(UserGroup)'' to role $(RoleName)';

    throw;
end catch;