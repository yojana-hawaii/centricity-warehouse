
USE CpsWarehouse
go

drop table if exists dbo.dimDate;
go
CREATE TABLE [dbo].[dimDate] (
    [DateKey]	  AS YEAR([date]) * 10000 + MONTH([date]) * 100 + DAY([date]),
	[Date]         DATE NOT NULL,
    [Year]         AS   (datepart(year,[date])),
    [FirstOfYear]  AS   (CONVERT([date],dateadd(year,datediff(year,(0),[date]),(0)))),
	[LastOfYear]   as CAST(CAST(YEAR([date]) AS VARCHAR(4)) + '-12-31' AS DATE),
    [Quarter]      AS   (datepart(quarter,[date])),
	[QuarterName]  as CASE 
					 WHEN DATENAME(qq, [date]) = 1
						THEN 'First'
					 WHEN DATENAME(qq, [date]) = 2
						THEN 'second'
					 WHEN DATENAME(qq, [date]) = 3
						THEN 'third'
					 WHEN DATENAME(qq, [date]) = 4
						THEN 'fourth'
					 END,
	[FirstOfQuater] as convert(date, DATEADD(qq, DATEDIFF(qq, 0, [date]), 0 )),
	[LastOfQuater]  as convert(date,DATEADD(dd, - 1, DATEADD(qq, DATEDIFF(qq, 0,[date]) + 1, 0))),
    [Month]        AS   (datepart(month,[date])),
    [MonthName]    AS   (datename(month,[date])),
    [FirstOfMonth] AS   (CONVERT([date],dateadd(month,datediff(month,(0),[date]),(0)))),
	[LastofMonth]   as EOMONTH([date]),
    [WeekOfYear]         AS   (datepart(week,[date])),
    [WeekName]     AS   (datename(weekday,[date])),
	[WeekOfMonth]  AS	DATEPART(week, [date]) - datepart(week, dateadd(day, 1, EOMONTH([date], -1) ) ) + 1,
    [DayOfWeek]    AS   (datepart(weekday,[date])),
	[FirstOfWeek]   as DATEADD(dd, - (DATEPART(dw, [date]) - 1), [date]),
	[LastOfWeek] as DATEADD(dd, 7 - (DATEPART(dw, [date])), [date]),
    [Day]          AS   (datepart(day,[date])),
	[DayOfYear]   as  DATENAME(dy, [date]),
	[DaySuffix]   as  CASE 
					 WHEN DAY([Date]) = 1 OR DAY([Date]) = 21 OR DAY([Date]) = 31
					  THEN 'st'
					 WHEN DAY([Date]) = 2 OR DAY([Date]) = 22 
					  THEN 'nd'
					 WHEN DAY([Date]) = 3 OR DAY([Date]) = 23
						THEN 'rd'
					 ELSE 'th'
					END,
    [YYYYMMDD]     AS   (CONVERT([char](8),[date],(112))),
    [Style101]     AS   (CONVERT([char](10),[date],(101))),
	[IsWeekend] as CASE 
         WHEN DATENAME(dw, [date]) = 'Sunday'
            OR DATENAME(dw, [date]) = 'Saturday'
            THEN 1
         ELSE 0
         END
    PRIMARY KEY CLUSTERED ([date])
);


go



drop proc if exists dbo.ssis_dimDate;
go
create proc dbo.ssis_dimDate
as 
begin

DECLARE @StartDate DATE = '18000101', @NumberOfYears INT = 300;

-- prevent set or regional settings from interfering with 
-- interpretation of dates / literals

SET DATEFIRST 7;
SET DATEFORMAT mdy;
SET LANGUAGE US_ENGLISH;

DECLARE @CutoffDate DATE = DATEADD(YEAR, @NumberOfYears, @StartDate);


INSERT [dbo].[dimDate]([date]) 
SELECT d
FROM
(
  SELECT d = DATEADD(DAY, rn - 1, @StartDate)
  FROM 
  (
    SELECT TOP (DATEDIFF(DAY, @StartDate, @CutoffDate)) 
      rn = ROW_NUMBER() OVER (ORDER BY s1.[object_id])
    FROM sys.all_objects AS s1
    CROSS JOIN sys.all_objects AS s2
    -- on my system this would support > 5 million days
    ORDER BY s1.[object_id]
  ) AS x
) AS y;

end
go
exec dbo.ssis_dimDate;
go