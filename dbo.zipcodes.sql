USE CpsWarehouse
GO

 
drop table if exists [dbo].[zipCodes];
go
CREATE TABLE [dbo].[zipCodes](
	[Zip] [int] NOT NULL,
	[City] [nvarchar](50) NOT NULL,
	[County] [nvarchar](50) NOT NULL,
	[Latitude] [float] NOT NULL,
	[Longitude] [float] NOT NULL,
	[Population_2015] [int] NOT NULL,
 CONSTRAINT [PK_zipCodes] PRIMARY KEY CLUSTERED 
(
	[zip] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


BULK
INSERT [dbo].[zipCodes]
from '\\fileserver\it\apps\sql\centricity-warehouse\zipcodes.csv'
with 
(
	fieldterminator = ',',
	rowterminator = '\n',
	firstrow = 2
);
go

alter table dbo.zipCodes 
add [Location] geography;
go

update dbo.zipCodes
set [Location] = geography::STPointFromText('POINT(' + cast([Longitude] as varchar(20) ) + ' ' + cast([Latitude] as varchar(20) ) + ')', 4326);

go



