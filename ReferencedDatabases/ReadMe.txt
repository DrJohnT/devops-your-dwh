
A "Reference Database" is one that you do not own, but need to reference in your database project.
Essentially a "Reference Database" is a databases which we reference, but do not deploy.  

Use SSDT to Import the database into an SSDT project and place the code within this folder.

Then add the following command is in the post-build event of any new database project so that it copies the DacPac to the DacPac folder.

copy /Y "$(ProjectDir)\bin\Debug\$(ProjectName).dacpac" "$(SolutionDir)\..\$(ProjectName).dacpac"