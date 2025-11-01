-- 008_add-windows-user.sql
-- Migration: Add Windows Authentication login and user for current Windows account

-- Enable contained database authentication
sp_configure 'contained database authentication', 1;
GO
RECONFIGURE;
GO

-- Get current Windows login
DECLARE @WindowsLogin NVARCHAR(100) = SYSTEM_USER;
DECLARE @DomainAccount NVARCHAR(100) = @WindowsLogin;

-- Create Windows Authentication login if it doesn't exist
DECLARE @CreateLogin NVARCHAR(MAX) = 
'IF NOT EXISTS (SELECT name FROM master.sys.server_principals WHERE name = ' + QUOTENAME(@DomainAccount, '''') + ')
BEGIN
  CREATE LOGIN ' + QUOTENAME(@DomainAccount) + ' FROM WINDOWS;
END';

EXEC sp_executesql @CreateLogin;

-- Create user and add to db_owner role in HistoryLake database
USE HistoryLake;
GO

DECLARE @CreateUser NVARCHAR(MAX) = 
'IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = ' + QUOTENAME(@DomainAccount, '''') + ')
BEGIN
    CREATE USER ' + QUOTENAME(@DomainAccount) + ' FOR LOGIN ' + QUOTENAME(@DomainAccount) + ';
    ALTER ROLE db_owner ADD MEMBER ' + QUOTENAME(@DomainAccount) + ';
END';

EXEC sp_executesql @CreateUser;

-- Grant server-level permissions
GRANT VIEW SERVER STATE TO [BUILTIN\Users];
GRANT VIEW ANY DEFINITION TO [BUILTIN\Users];
GRANT CONNECT SQL TO [BUILTIN\Users];

-- Print confirmation
PRINT 'Windows Authentication has been configured for ' + @DomainAccount;
PRINT 'User has been added to db_owner role in HistoryLake database';
GO