SET IDENTITY_INSERT dbo.Lake_Tournaments ON;

INSERT INTO dbo.Lake_Tournaments (
    Id, FileName, XmlContent, UploadTime, FileSize,
    Sha256Hash, OriginalCreationTime, OriginalLastWriteTime,
    Processed, SessionCode
)
SELECT
    Id, FileName, XmlContent, UploadTime, FileSize,
    Sha256Hash, OriginalCreationTime, OriginalLastWriteTime,
    Processed, SessionCode
FROM dbo.Lake_Tournaments_Backup;

SET IDENTITY_INSERT dbo.Lake_Tournaments OFF;
