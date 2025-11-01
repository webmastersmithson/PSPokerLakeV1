
USE [HistoryLake]
GO

/****** Object:  Table [dbo].[Lake_Tables]    Script Date: 01/11/2025 21:00:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Lake_Tables](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[FileName] [nvarchar](260) NOT NULL,
	[XmlContent] [xml] NOT NULL,
	[UploadTime] [datetime2](7) NOT NULL,
	[FileSize] [bigint] NOT NULL,
	[Sha256Hash] [char](64) NOT NULL,
	[OriginalCreationTime] [datetime2](7) NULL,
	[OriginalLastWriteTime] [datetime2](7) NULL,
	[Processed] [bit] NOT NULL,
	[SessionCode] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

ALTER TABLE [dbo].[Lake_Tables] ADD  DEFAULT (sysutcdatetime()) FOR [UploadTime]
GO

ALTER TABLE [dbo].[Lake_Tables] ADD  DEFAULT ((0)) FOR [Processed]
GO

