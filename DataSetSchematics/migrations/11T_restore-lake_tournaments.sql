SET IDENTITY_INSERT dbo.Lake_Tables ON;

INSERT INTO dbo.Lake_Tables (
    Id, FileName, XmlContent, UploadTime, FileSize,
    Sha256Hash, OriginalCreationTime, OriginalLastWriteTime,
    Processed, SessionCode
)
SELECT
    Id, FileName, XmlContent, UploadTime, FileSize,
    Sha256Hash, OriginalCreationTime, OriginalLastWriteTime,
    Processed, SessionCode
FROM dbo.Lake_Tables_Backup;

SET IDENTITY_INSERT dbo.Lake_Tables OFF;
