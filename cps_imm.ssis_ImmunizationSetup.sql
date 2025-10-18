
use CpsWarehouse
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
drop table if exists [CpsWarehouse].[cps_imm].[ImmunizationSetup];
create table [CpsWarehouse].[cps_imm].[ImmunizationSetup](
	ImmunizationSetupID int identity(1,1) not null,
	--[Active] bit not null,
	[VisDate] [date]  null, /*vis date moved to level 2 after July 2022 KB. keep it nullable for now */
	/*alter table [CpsWarehouse].[cps_imm].[ImmunizationSetup] alter column [VisDate] [date]  null*/
	[Vaccine] [nvarchar](30) NOT NULL,
	[VaccineCVX] varchar(3) null,
	[VaccineCVX_ID] nvarchar(255) not null,
	[Brand] nvarchar(400),
	[BrandCVX] varchar(3) null,
	[BrandCVX_ID] nvarchar(255) not null,
	[BodySite] nvarchar(max) not null,
	[Dose] float null,
	[Manufacturer] nvarchar(255) null,
	[GPI] nvarchar(50) null,
	[LotNumber_ID] nvarchar(255) not null,
	[LotNumber] nvarchar(50) null,
	[LotExpiration] date null,
	[LotNumberAddedDate] date null,
	[LotNumberAddedBy] nvarchar(255) null,
	[NDC] nvarchar(15) not null,
	[Route] nvarchar(10) null,
	[Unit] nvarchar(5) null,
	[OrderDescription] nvarchar(50) null,
	[OrderActiveEMR] nvarchar(10) not null,
	[OrderActiveBilling] nvarchar(10) not null,
	[ICD10Code] nvarchar(5) null,
	Series nvarchar(5) null, 
	Series_Min_Age nvarchar(5) null, 
	Series_Max_age nvarchar(5) null,
	Series_Interval nvarchar(5) null,
) 



GO

/* Added 7/29/19 
Active column
* 1 if exists in centricity
* 0 if already removed
alter table [cps_imm].[ImmunizationSetup]
add [Active] bit

alter table [cps_imm].[ImmunizationSetup]
add  ImmunizationSetupID int identity(1,1) not null

select * from [cps_imm].[ImmunizationSetup]
*/


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
if object_id('cps_imm.ssis_ImmunizationSetup') is not null 
begin
drop PROCEDURE [cps_imm].[ssis_ImmunizationSetup] 
end 
go
CREATE procedure [cps_imm].[ssis_ImmunizationSetup]
as begin

truncate table [cps_imm].[ImmunizationSetup]

IF OBJECT_ID('tempdb..#Level1') IS NOT NULL DROP TABLE #Level1;
IF OBJECT_ID('tempdb..#Level2') IS NOT NULL DROP TABLE #Level2;
IF OBJECT_ID('tempdb..#Level3') IS NOT NULL DROP TABLE #Level3;
IF OBJECT_ID('tempdb..#LevelOne') IS NOT NULL DROP TABLE #LevelOne;
IF OBJECT_ID('tempdb..#LevelTwo') IS NOT NULL DROP TABLE #LevelTwo;
IF OBJECT_ID('tempdb..#FinalOne') IS NOT NULL DROP TABLE #FinalOne;
IF OBJECT_ID('tempdb..#FinalTwo') IS NOT NULL DROP TABLE #FinalTwo;
IF OBJECT_ID('tempdb..#finalfinaltwo') IS NOT NULL DROP TABLE #finalfinaltwo;
IF OBJECT_ID('tempdb..#Final3') IS NOT NULL DROP TABLE #Final3;
IF OBJECT_ID('tempdb..#Verify') IS NOT NULL DROP TABLE #Verify;


/**Level 1 NameSpace - KPHC immunization,Immunization type (vaccine group)
select * from #level1
*********************************************************/
drop table if exists #level1;
SELECT 
	(Namespace+'.'+ NodeName) AS Level1NameSpace,
	ListOrder AS ImmuTypeListOrder,ContentDefault AS ImmuTypeContentDefault,
	DisplayName AS ImmuType, Namespace AS Level0NameSpace
INTO #Level1
FROM [cpssql].CentricityPS.DBO.ContentList
--WHERE Namespace = 'ge.imm.cusl.1734341538050570'
WHERE Namespace in (/*'GE.IMM.CUSL.1924155241631230'Covid-19 Custom List,*/'GE.IMM.CUSL.1734341538050570'/*1.KPHC Custom List*/)
ORDER BY ListOrder;


/**Level One Additional NameSpace - CVX,VisDate,Inst,series,series min age,series max age,series min interval,route,body site,dose,unit
select * from #LevelOne
***************************************************************************************************************************************/
drop table if exists #LevelOne;
SELECT 
	One.Level0NameSpace,One.Level1NameSpace,One.ImmuTypeListOrder,One.ImmuTypeContentDefault,One.ImmuType,
	c.Namespace AS ImmNameNameSpace, 
	(c.Namespace + '.SCHD.Series') AS Series, 
	(c.Namespace + '.SCHD.Series.MIN_AGE') AS Series_Min_Age, 
	(c.Namespace + '.SCHD.Series.MAX_AGE') AS Series_Max_age, 
	(c.Namespace + '.SCHD.Series.MIN_INTERVAL') AS Series_Min_Interval, 
	(c.Namespace + '.CVX') AS CVX, 
	(c.Namespace + '.INST') AS Instruction,
	(c.Namespace + '.VIS') AS VisDate 
INTO #LevelOne
FROM [cpssql].CentricityPS.DBO.ContentList c
	INNER JOIN #Level1 One ON c.Namespace = One.Level1NameSpace;

/*Change name space to value - first group
only using Visdate and series for now.
no need for listorder and content default here
select * from #FinalOne
******************************************/
drop table if exists #FinalOne;
SELECT distinct
	One.Level0NameSpace,One.Level1NameSpace,One.ImmuTypeListOrder,One.ImmuTypeContentDefault,One.ImmuType,
	case One.ImmuType 
		when 'Measles' then '05'
		when 'Mumps' then '07'
		when 'Rubella' then '06'
		when 'MMR' then '03'
		when 'Varicella' then '21'
	else c2.DisplayName end  CVX,
	--MAX(c4.DisplayName) Series,
	c4.DisplayName Series,
	c5.DisplayName Series_Min_Age,
	c6.DisplayName Series_Max_age,
	c7.DisplayName Series_Interval,
	
	CAST(c8.DisplayName AS DATE) AS VisDate
INTO #FinalOne
FROM #LevelOne One
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c2 ON One.CVX = c2.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c4 ON One.Series = c4.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c5 ON One.Series_Min_Age = c5.Namespace and c4.contentgroup = c5.contentgroup 
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c6 ON One.Series_Max_age = c6.Namespace and c4.contentgroup = c6.contentgroup 
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c7 ON One.Series_Min_Interval = c7.Namespace and c4.contentgroup = c7.contentgroup 
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c8 ON One.VisDate = c8.Namespace
--Group BY  One.Level0NameSpace,One.Level1NameSpace,One.ImmuTypeListOrder,One.ImmuTypeContentDefault,One.ImmuType,c8.DisplayName, c2.displayName;

/*****Quick query level One temp tables***
select * from #Level1						-- 28 different type of vaccine
select * from #LevelOne						-- each vaccine has CVX,VisDate,Inst,series,series min age,series max age,series min interval,route,body site,dose,unit if need - 85
select  ImmuType FROM #LevelOne				-- selected only visdate and series for each vaccine - 21, other 2 are just for historical
select * from #FinalOne
********************************************************/


/****Level 2 NameSpace - Immunization Name
select * from #level2
***************************************/
drop table if exists #Level2;
SELECT 
	One.Level0NameSpace,One.Level1NameSpace,
	(c.Namespace+'.'+c.NodeName) AS Level2NameSpace,
	One.ImmuType,One.ImmuTypeListOrder,One.ImmuTypeContentDefault,
	c.ListOrder AS ImmuNameListorder,c.ContentDefault AS ImmuNameContentDefault,
	c.DisplayName AS ImmuName
INTO #Level2
FROM [cpssql].CentricityPS.DBO.ContentList c
	INNER JOIN #Level1 One ON c.Namespace = One.Level1NameSpace;


/*****************************************************************************************************************************
Level Two Additional NameSpace - GPI,NDC,Manufacturer,route, body site, dose, unit,order category,order desc,DX code, DX desc
select * from #leveltwo
******************************************************************************************************************************/
drop table if exists #LevelTwo;
SELECT DISTINCT
	Two.Level0NameSpace,Two.Level1NameSpace,Two.Level2NameSpace,
	Two.ImmuName,Two.ImmuNameListorder,ImmuNameContentDefault,
	(Two.Level2NameSpace + '.BodySite') AS BodySite,
	(Two.Level2NameSpace + '.CVX') AS CVX,
	(Two.Level2NameSpace + '.DDID') AS DDID,
	(Two.Level2NameSpace + '.DNID') AS DNID,
	(Two.Level2NameSpace + '.Dose') AS Dose,
	(Two.Level2NameSpace  + '.GPI') AS GPI,
	(Two.Level2NameSpace  + '.KDC') AS KDC,
	(Two.Level2NameSpace + '.MFR') AS MFR,
	(Two.Level2NameSpace + '.NDC') AS NDC, 
	(Two.Level2NameSpace + '.Order') AS 'Order',
	(Two.Level2NameSpace + '.Order.Category') AS OrderCategory,
	(Two.Level2NameSpace + '.Order.CategoryID') AS OrderCategoryID,
	(Two.Level2NameSpace + '.Order.Comment') AS OrderComment,
	(Two.Level2NameSpace + '.Order.Description') AS OrderDescription,
	(Two.Level2NameSpace + '.Order.DXCode') AS OrderDxCode,
	(Two.Level2NameSpace + '.Order.DxDesc') AS OrderDxDesc,
	(Two.Level2NameSpace + '.Order.Modifier') AS OrderModifier,
	(Two.Level2NameSpace + '.Order.Priority') AS OrderPriority,
	(Two.Level2NameSpace + '.Order.Type') AS OrderType,
	(Two.Level2NameSpace + '.Order.Units') AS OrderUnits,
	(Two.Level2NameSpace + '.ROUTE') AS 'Route', 
	(Two.Level2NameSpace + '.UNIT') AS Unit
INTO #LevelTwo
FROM [cpssql].CentricityPS.DBO.ContentList c
	INNER JOIN #Level2 Two ON c.Namespace = Two.Level1NameSpace;


/***Change name space to value - second group
select * from #finalTwo
******************************************/
drop table if exists #FinalTwo;
SELECT 
	Two.Level0NameSpace,Two.Level1NameSpace,Two.Level2NameSpace,Two.ImmuName,
	Two.ImmuNameListorder,Two.ImmuNameContentDefault,
	c1.ListOrder AS SiteListOrder,c1.ContentDefault AS SiteContentDefault,c1.DisplayName AS BodySite,
	c2.DisplayName CVX,
	c3.DisplayName GPI,
	c5.DisplayName Dose,
	isnull(c8.DisplayName,'na') MFR,
	c9.DisplayName NDC,
	c11.DisplayName OrderCategory,
	c14.DisplayName OrderDescription,
	c15.DisplayName OrderDxCode,
	c16.DisplayName OrderDxDesc,
	c21.DisplayName [Route],
	c22.DisplayName Unit,
	Two.MFR MFRNameSpace
INTO #FinalTwo
FROM #LevelTwo Two
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c1 ON Two.BodySite = c1.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c2 ON Two.CVX = c2.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c3 ON Two.GPI = c3.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c5 ON Two.Dose = c5.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c8 ON Two.MFR = c8.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c9 ON Two.NDC = c9.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c11 ON Two.OrderCategory = c11.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c14 ON Two.OrderDescription = c14.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c15 ON Two.OrderDxCode = c15.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c16 ON Two.OrderDxDesc = c16.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c21 ON Two.[Route] = c21.Namespace
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c22 ON Two.Unit = c22.Namespace;


/***Combine Body Site into One Row
select * from #finalfinaltwo
**************************************/
drop table if exists #finalfinaltwo;
SELECT DISTINCT
	two.Level0NameSpace,two.Level1NameSpace,two.Level2NameSpace,two.MFRNameSpace,two.ImmuName, 
	two.GPI,two.CVX,two.ImmuNameListorder,two.ImmuNameContentDefault,
	SUBSTRING (
	(
		SELECT ', ' + two1.BodySite AS [text()]
		FROM #FinalTwo two1
		WHERE two1.ImmuName = two.ImmuName
		ORDER BY two1.ImmuName
		FOR XML PATH ('')
	),2 ,1000) [BodySite], 
	two.Dose, two.MFR,two.NDC,two.OrderCategory,two.OrderDescription,two.OrderDxCode,two.OrderDxDesc,two.Route,two.Unit
INTO #finalfinaltwo
FROM #FinalTwo two


/*********Quick query level Two temp tables******
SELECT * FROM #Level2			-- 28 different type of vaccine with 85 vaccine type - 7 repeats, some more than 2 times
select * from #LevelTwo			-- each vaccine has GPI,NDC,Manufacturer,route, body site, dose, unit,order category,order desc,DX code, DX desc - 85
select * from #FinalTwo			-- all values and order and content default for second level - 259
select * from #finalFinalTwo	-- combine all body sites - 87
********************************************************/


/******Level 3 NameSpace - Lot Number and expiration date
select * from #level3
***************************************/
drop table if exists #level3;
SELECT 
	Two.Level0NameSpace,Two.Level1NameSpace,Two.Level2NameSpace,
	(Two.Level2NameSpace+'.'+c.NodeName) AS Level3NameSpace,
	two.mfr mfrnamespace,
	c.DisplayName AS Mfr,
	(Two.Level2NameSpace+'.'+c.NodeName + '.LOT') AS Lot,
	(Two.Level2NameSpace+'.'+c.NodeName + '.LOT.EXP') AS LotExp
INTO #level3 
FROM [cpssql].CentricityPS.DBO.ContentList c
	INNER JOIN #LevelTwo Two ON c.Namespace = Two.MFR;

drop table if exists #Final3
SELECT 
	three.Level0NameSpace,three.Level1NameSpace,three.Level2NameSpace,three.Level3NameSpace,three.mfr,three.mfrnamespace,
	c1.DisplayName AS Lot,c2.DisplayName AS LotExp,
	convert(date,c1.Created) LotNumberCreatedDate,
	convert(nvarchar(255),c1.CreatedBy) LotNumberCreatedBy
INTO #Final3
FROM #level3 three
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c1 ON c1.Namespace = three.Lot
	LEFT JOIN [cpssql].CentricityPS.DBO.ContentList c2 ON (c2.Namespace = three.LotExp and c1.ContentGroup = c2.ContentGroup)


/*********Quick query level Three temp tables******
select * from #Final3
SELECT * FROM #Level3 order by Level3NameSpace			-- mfr, lot number and expiration dates
select * from #finalfinaltwo order by Level2NameSpace			-- 
select * from #finalOne order by Level1NameSpace
********************************************************/


/****combine first group, second and third  group
******************************************/
drop table if exists #verify;
;with u as(
	SELECT DISTINCT 1 Active,
		convert(nvarchar(30),One.ImmuType) ImmuType,
		One.VisDate,
		One.Series, One.Series_Min_Age, One.Series_Max_age, One.Series_Interval,
		One.CVX TypeCVX,
		one.Level1NameSpace [VaccineCVX_ID],
		two.Level2NameSpace [BrandCVX_ID],
		three.Level3NameSpace + '_' + isnull(three.Lot,'x') [LotNumber_ID],
		convert(nvarchar(255),Two.ImmuName) ImmuName,
		Two.CVX NameCVX,
		convert(nvarchar(max),Two.BodySite) BodySite,
		convert(float,Two.Dose) Dose,
		convert(nvarchar(255),Two.MFR) MFR,
		two.GPI,
		convert(nvarchar(50),three.Lot) Lot,
		convert(date,three.LotExp) LotExp,
		three.LotNumberCreatedDate [LotNumberAddedDate],
		three.LotNumberCreatedBy [LotNumberAddedBy],
		convert(nvarchar(15),Two.NDC) NDC,
		convert(nvarchar(10),two.Route) [Route],
		convert(nvarchar(5),Two.Unit) Unit,
		convert(nvarchar(50),Two.OrderDescription) OrderDescription,
		(CASE WHEN code.ordcodestatus = 'A' THEN 'Active'
			ELSE 'Problem'
			END) OrderActiveInEMR,
		(CASE 
			WHEN p.code IS NULL THEN 'Problem'
			ELSE 'Active'
		END) ActiveInBilling,
		Two.OrderDxCode ICD10Code
		--into #verify
	FROM #FinalOne One
		LEFT JOIN #finalfinaltwo Two ON One.Level1NameSpace = Two.Level1NameSpace
		LEFT JOIN #Final3 three on two.MFRNameSpace = three.mfrnamespace
		LEFT JOIN [cpssql].CentricityPS.DBO.ORDERCODES code ON code.description = Two.OrderDescription and code.ordCodeStatus = 'A'
		LEFT JOIN [cpssql].CentricityPS.DBO.[Procedures] p ON ('CPT-'+p.Code) = code.CODE
)
select distinct * 
into #verify
from u 
where ndc is not null




-- exec tempdb.dbo.sp_help N'#verify' 

insert into cps_imm.[ImmunizationSetup]( 
	Vaccine, VisDate, VaccineCVX,[VaccineCVX_ID],[BrandCVX_ID],[LotNumber_ID], Brand, BrandCVX, BodySite,GPI,
		Series, Series_Min_Age, Series_Max_age,Series_Interval,
	Dose, Manufacturer, LotNumber, LotExpiration,[LotNumberAddedDate],[LotNumberAddedBy], NDC, Route, Unit, OrderDescription,OrderActiveEMR, OrderActiveBilling, ICD10Code)
select 
	ImmuType, VisDate, TypeCVX,[VaccineCVX_ID],[BrandCVX_ID],[LotNumber_ID], ImmuName, NameCVX, BodySite,GPI, 
	Series, Series_Min_Age, Series_Max_age,Series_Interval,
	Dose, MFR, Lot, LotExp,[LotNumberAddedDate],[LotNumberAddedBy], NDC, Route, Unit, OrderDescription,OrderActiveInEMR, ActiveInBilling, ICD10Code
from #verify


end
GO
