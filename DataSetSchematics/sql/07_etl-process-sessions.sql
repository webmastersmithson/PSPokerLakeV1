-- 007_etl-process-sessions.sql
-- Migration: Creates Lake_Sessions staging table and ETL procedure

-- Create Lake staging table if not exists 
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Lake_Sessions')
BEGIN
    CREATE TABLE dbo.Lake_Sessions
    (
        Id INT IDENTITY(1,1) PRIMARY KEY,

        SessionCode BIGINT,
        FileName NVARCHAR(260),
    XmlContent XML,
        Sha256Hash CHAR(64),
        processed BIT NOT NULL DEFAULT 0,
        ClientVersion NVARCHAR(20),
        Mode NVARCHAR(10),
    GameType NVARCHAR(100),
        TableName NVARCHAR(100),
 TableCurrency NVARCHAR(3),
    SmallBlind NVARCHAR(20),
        BigBlind NVARCHAR(20),
 Duration NVARCHAR(20),
        GameCount INT,
  StartDate DATETIME2(0),
        Currency NVARCHAR(3),
        Nickname NVARCHAR(100),
        Bets DECIMAL(18,2),
        Wins DECIMAL(18,2),
        ChipsIn DECIMAL(18,2),
 ChipsOut DECIMAL(18,2),
   StatusPoints DECIMAL(18,2),
     AwardPoints DECIMAL(18,2),
        IPoints DECIMAL(18,2),
        TableSize INT,
        CreatedDate DATETIME2(0) DEFAULT GETDATE()
    );

    -- Add unique constraints per conventions
    CREATE UNIQUE NONCLUSTERED INDEX UX_Lake_Sessions_Hash 
    ON dbo.Lake_Sessions(Sha256Hash) 
    WHERE Sha256Hash IS NOT NULL;

    CREATE UNIQUE NONCLUSTERED INDEX UX_Lake_Sessions_SessionCode 
    ON dbo.Lake_Sessions(SessionCode) 
    WHERE SessionCode IS NOT NULL;
END;
GO

-- Create final sessions table if it doesn't exist
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Sessions')
BEGIN
    CREATE TABLE dbo.Sessions
    (
    SessionId BIGINT PRIMARY KEY,
        ClientVersion NVARCHAR(20),
        Mode NVARCHAR(10),
        GameType NVARCHAR(100),
 TableName NVARCHAR(100),
        TableCurrency NVARCHAR(3),
        SmallBlind NVARCHAR(20),
        BigBlind NVARCHAR(20),
        Duration NVARCHAR(20),
        GameCount INT,
        StartDate DATETIME2(0),
        Currency NVARCHAR(3),
        Nickname NVARCHAR(100),
        Bets DECIMAL(18,2),
     Wins DECIMAL(18,2),
        ChipsIn DECIMAL(18,2),
        ChipsOut DECIMAL(18,2),
     StatusPoints DECIMAL(18,2),
   AwardPoints DECIMAL(18,2),
        IPoints DECIMAL(18,2),
        TableSize INT,
    CreatedDate DATETIME2(0) DEFAULT GETDATE(),
        LastModifiedDate DATETIME2(0) DEFAULT GETDATE()
    );

    -- Create indices
    CREATE NONCLUSTERED INDEX IX_Sessions_StartDate ON dbo.Sessions(StartDate);
    CREATE NONCLUSTERED INDEX IX_Sessions_Nickname ON dbo.Sessions(Nickname);
END;
GO

-- ETL Procedure that processes Lake_Sessions table
CREATE OR ALTER PROCEDURE dbo.Etl_ProcessLakeSessions
    @BatchSize INT = 500
AS
BEGIN
    SET NOCOUNT ON;

    -- Temp table to hold batch
    IF OBJECT_ID('tempdb..#Batch') IS NOT NULL DROP TABLE #Batch;
    CREATE TABLE #Batch
    (
        Id INT,
        SessionCode BIGINT,
        ClientVersion NVARCHAR(20),
        Mode NVARCHAR(10),
        GameType NVARCHAR(100),
        TableName NVARCHAR(100),
      TableCurrency NVARCHAR(3),
        SmallBlind NVARCHAR(20),
     BigBlind NVARCHAR(20),
        Duration NVARCHAR(20),
 GameCount INT,
        StartDate DATETIME2(0),
     Currency NVARCHAR(3),
        Nickname NVARCHAR(100),
        Bets DECIMAL(18,2),
        Wins DECIMAL(18,2),
        ChipsIn DECIMAL(18,2),
        ChipsOut DECIMAL(18,2),
        StatusPoints DECIMAL(18,2),
        AwardPoints DECIMAL(18,2),
        IPoints DECIMAL(18,2),
        TableSize INT
    );

    -- Get batch of unprocessed rows
    ;WITH cte AS (
      SELECT TOP (@BatchSize)
  Id, SessionCode, ClientVersion, Mode, GameType, TableName,
       TableCurrency, SmallBlind, BigBlind, Duration, GameCount,
    StartDate, Currency, Nickname, Bets, Wins, ChipsIn, ChipsOut,
            StatusPoints, AwardPoints, IPoints, TableSize
    FROM dbo.Lake_Sessions
   WHERE processed = 0
        ORDER BY Id
    )
    UPDATE cte
    SET processed = 1
    OUTPUT 
        inserted.Id,
  inserted.SessionCode,
      inserted.ClientVersion,
     inserted.Mode,
    inserted.GameType,
      inserted.TableName,
        inserted.TableCurrency,
 inserted.SmallBlind,
     inserted.BigBlind,
        inserted.Duration,
      inserted.GameCount,
        inserted.StartDate,
      inserted.Currency,
   inserted.Nickname,
        inserted.Bets,
  inserted.Wins,
        inserted.ChipsIn,
        inserted.ChipsOut,
        inserted.StatusPoints,
        inserted.AwardPoints,
      inserted.IPoints,
    inserted.TableSize
    INTO #Batch;

    -- Merge batch into Sessions
 MERGE dbo.Sessions AS target
    USING #Batch AS source
    ON target.SessionId = source.SessionCode
    WHEN MATCHED THEN
        UPDATE SET
            target.ClientVersion = source.ClientVersion,
            target.Mode = source.Mode,
      target.GameType = source.GameType,
            target.TableName = source.TableName,
            target.TableCurrency = source.TableCurrency,
            target.SmallBlind = source.SmallBlind,
            target.BigBlind = source.BigBlind,
            target.Duration = source.Duration,
    target.GameCount = source.GameCount,
    target.StartDate = source.StartDate,
     target.Currency = source.Currency,
    target.Nickname = source.Nickname,
            target.Bets = source.Bets,
     target.Wins = source.Wins,
    target.ChipsIn = source.ChipsIn,
            target.ChipsOut = source.ChipsOut,
            target.StatusPoints = source.StatusPoints,
     target.AwardPoints = source.AwardPoints,
     target.IPoints = source.IPoints,
       target.TableSize = source.TableSize,
    target.LastModifiedDate = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (
            SessionId, ClientVersion, Mode, GameType, TableName, TableCurrency,
SmallBlind, BigBlind, Duration, GameCount, StartDate, Currency,
  Nickname, Bets, Wins, ChipsIn, ChipsOut, StatusPoints,
    AwardPoints, IPoints, TableSize
        )
        VALUES (
source.SessionCode, source.ClientVersion, source.Mode, source.GameType,
       source.TableName, source.TableCurrency, source.SmallBlind, source.BigBlind,
            source.Duration, source.GameCount, source.StartDate, source.Currency,
        source.Nickname, source.Bets, source.Wins, source.ChipsIn, source.ChipsOut,
            source.StatusPoints, source.AwardPoints, source.IPoints, source.TableSize
        );

 -- Cleanup
    IF OBJECT_ID('tempdb..#Batch') IS NOT NULL DROP TABLE #Batch;
END;
GO

-- Create procedure to initially populate Lake_Sessions from XML files
CREATE OR ALTER PROCEDURE dbo.Import_XmlToLakeSessions
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Lake_Sessions (
        SessionCode, FileName, XmlContent, Sha256Hash,
        ClientVersion, Mode, GameType, TableName, TableCurrency,
        SmallBlind, BigBlind, Duration, GameCount, StartDate,
        Currency, Nickname, Bets, Wins, ChipsIn, ChipsOut,
        StatusPoints, AwardPoints, IPoints, TableSize
    )
    SELECT
    x.v.value('../@sessioncode', 'BIGINT') AS SessionCode,
     f.FileName,
    f.XmlContent,
        f.Sha256Hash,
        x.v.value('(client_version)[1]', 'NVARCHAR(20)') AS ClientVersion,
        x.v.value('(mode)[1]', 'NVARCHAR(10)') AS Mode,
        x.v.value('(gametype)[1]', 'NVARCHAR(100)') AS GameType,
    x.v.value('(tablename)[1]', 'NVARCHAR(100)') AS TableName,
        x.v.value('(tablecurrency)[1]', 'NVARCHAR(3)') AS TableCurrency,
        x.v.value('(smallblind)[1]', 'NVARCHAR(20)') AS SmallBlind,
        x.v.value('(bigblind)[1]', 'NVARCHAR(20)') AS BigBlind,
        x.v.value('(duration)[1]', 'NVARCHAR(20)') AS Duration,
        x.v.value('(gamecount)[1]', 'INT') AS GameCount,
        x.v.value('(startdate)[1]', 'DATETIME2(0)') AS StartDate,
        x.v.value('(currency)[1]', 'NVARCHAR(3)') AS Currency,
    x.v.value('(nickname)[1]', 'NVARCHAR(100)') AS Nickname,
        CAST(REPLACE(x.v.value('(bets)[1]', 'NVARCHAR(20)'), '€', '') AS DECIMAL(18,2)) AS Bets,
        CAST(REPLACE(x.v.value('(wins)[1]', 'NVARCHAR(20)'), '€', '') AS DECIMAL(18,2)) AS Wins,
        CAST(REPLACE(x.v.value('(chipsin)[1]', 'NVARCHAR(20)'), '€', '') AS DECIMAL(18,2)) AS ChipsIn,
  CAST(REPLACE(x.v.value('(chipsout)[1]', 'NVARCHAR(20)'), '€', '') AS DECIMAL(18,2)) AS ChipsOut,
        x.v.value('(statuspoints)[1]', 'DECIMAL(18,2)') AS StatusPoints,
        x.v.value('(awardpoints)[1]', 'DECIMAL(18,2)') AS AwardPoints,
    x.v.value('(ipoints)[1]', 'DECIMAL(18,2)') AS IPoints,
      x.v.value('(tablesize)[1]', 'INT') AS TableSize
  FROM dbo.ImportedXml f
    CROSS APPLY XmlContent.nodes('/session/general') AS x(v)
    WHERE XmlContent.value('(/session/@sessioncode)[1]', 'BIGINT') IS NOT NULL
 AND NOT EXISTS (
        SELECT 1 
FROM dbo.Lake_Sessions s 
  WHERE s.Sha256Hash = f.Sha256Hash
     OR s.SessionCode = XmlContent.value('(/session/@sessioncode)[1]', 'BIGINT')
    );
END;
GO

EXEC dbo.Etl_ProcessLakeSessions;