The ReferencedDatabases sub-directory contains databases which we reference, but do not deploy.  

Please ensure the following command is in the post-build event of any new database project.

copy /Y "$(ProjectDir)\bin\Debug\$(ProjectName).dacpac" "$(SolutionDir)\..\$(ProjectName).dacpac"