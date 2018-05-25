/* 
 * These folders are ONLY for user permission files 
 *
 * Permission CSV files in the ALL folder get run against ALL environments
 * Permission CSV files in the TST folder get run against the TST environment ONLY
 * Permission CSV files in the PROD folder get run against the PROD environment ONLY
 * 
 * The permission CSV files must have the name of the database along with the word UserPermissions
 * Format DatabaseName.UserPermissions.csv
 * e.g. DWH_QuantumDM.UserPermissions.csv
 * 
 * Note that TST and PROD are the names from config.xml
 * 
 * A UserPermissions.csv file has three columns: UserGroup,RoleName,DefaultSchemaName
 */