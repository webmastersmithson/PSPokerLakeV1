DROP TABLE dbo.Lake_Tournaments;
DROP TABLE dbo.Lake_Tables;

-- Recreate Lake_Tournaments
CREATE TABLE dbo.Lake_Tournaments (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FileName NVARCHAR(260) NOT NULL,
    XmlContent XML NOT NULL,
    UploadTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FileSize BIGINT NOT NULL,
    Sha256Hash CHAR(64) NOT NULL,
    OriginalCreationTime DATETIME2 NULL,
    OriginalLastWriteTime DATETIME2 NULL,
    Processed BIT NOT NULL DEFAULT 0,
    SessionCode NVARCHAR(100) NULL
);

-- Recreate Lake_Tables
CREATE TABLE dbo.Lake_Tables (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FileName NVARCHAR(260) NOT NULL,
    XmlContent XML NOT NULL,
    UploadTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    FileSize BIGINT NOT NULL,
    Sha256Hash CHAR(64) NOT NULL,
    OriginalCreationTime DATETIME2 NULL,
    OriginalLastWriteTime DATETIME2 NULL,
    Processed BIT NOT NULL DEFAULT 0,
    SessionCode NVARCHAR(100) NULL
);
