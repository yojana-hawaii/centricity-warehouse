
use CpsWarehouse
go

drop table if exists [cps_orders].[OrderCodesAndCategories];
go
CREATE TABLE [cps_orders].[OrderCodesAndCategories] (
    [OrderCodeID]           NUMERIC (19)   NOT NULL,
    [OrderCatID]            NUMERIC (19)   NULL,
    [OrderCode]             VARCHAR (20)   NOT NULL,
    [OrderDesc]             VARCHAR (255)  NOT NULL,
    [OrderType]             NVARCHAR (1)   NOT NULL,
    [Inactive]				smallint    NOT NULL,
	[Total_1Year]		int			 null,
	[Total_2Years]		int			 null,
	[Total_5Years]		int			 null,
	AUCRequired			varchar(5)	null,
	AUCOrderCode		varchar(10)		null,
    [OrderPrompt]           VARCHAR (2000) NULL,
    [Duration]              NUMERIC (19)   NULL,
    [DurationUnits]         VARCHAR (1)    NULL,
    Unit             NUMERIC (19)   NULL,
	Common		varchar(1) not null,
    [IsTOC]                 VARCHAR (1)    NULL,
    [CategoryName]          NVARCHAR (80)  NULL,
    [OrderClassification]   VARCHAR (10)    NOT NULL,
    [DefaultClassification] VARCHAR (30)   NULL,
    PRIMARY KEY CLUSTERED ([OrderCodeID] ASC)
);

go

drop proc if exists [cps_orders].[ssis_OrderCodesAndCategories]
go

CREATE procedure [cps_orders].[ssis_OrderCodesAndCategories]
as begin

truncate table [cps_orders].[OrderCodesAndCategories];
with one_year_hist as  (
	select o.OrderCodeID, count(*) Total_1Year
	from CpsWarehouse.cps_orders.Fact_all_orders o
	where o.OrderDate >= dateadd(year, -1, convert(date, getdate() ) )
	group by o.OrderCodeID
)
,two_year_hist as  (
	select o.OrderCodeID, count(*) Total_2Years
	from CpsWarehouse.cps_orders.Fact_all_orders o
	where o.OrderDate >= dateadd(year, -2, convert(date, getdate() ) )
	group by o.OrderCodeID
)
,five_year_hist as  (
	select o.OrderCodeID, count(*) Total_5Years
	from CpsWarehouse.cps_orders.Fact_all_orders o
	where o.OrderDate >= dateadd(year, -5, convert(date, getdate() ) )
	group by o.OrderCodeID
)
,u as (
	select 
		cod.ordcodeid OrderCodeID, 
		cod.ordcatid OrderCatID, 
		cod.Code OrderCode, 
		cod.OrderType OrderType,
		cod.Description OrderDesc, 
		case when ltrim(rtrim(cod.OrderPrompt)) = '' then null else ltrim(rtrim(cod.OrderPrompt)) end OrderPrompt, 
		cod.Duration Duration, 
		case when ltrim(rtrim(cod.DurationUnits)) = '' then null else ltrim(rtrim(cod.DurationUnits)) end  DurationUnits, 
		cod.NumVisits Unit, 
		cod.IsTOC IsTOC, 
		cod.Common Common,
		case cod.OrdCodeStatus 
			when 'o' then 1 
			when 'a' then 0
		end Inactive,
		isnull(cat.CatName,'Deleted') CategoryName,

			case 
				when cat.ORDCATID = 1746438436203670 then 'HDRS'
				when (cod.Classification = 2 or cat.DefaultClassification = 2) 
					or cod.Description like 'x-ray%'
					then 'RAD'
				when cat.ORDCATID = 1541066514751530 then 'DLS'
				when cat.ORDCATID = 1722264307059430 then 'HPL'
				when cat.ORDCATID in (1842599424829680,1811408067272850) then 'CLH'
				when cat.ORDCATID = 1808912758187930 then 'DOH'
				when cat.ORDCATID in (1781618115217780) 
					or cod.Description in ('Diabetes Clinic','Diabetes 101')
					then 'INT'
			
				when cod.code like 'CPT-99%' 
						and cod.ordCatId in (1725635117026480 , 1537364713000640)
					then 'E&M'


				when cod.orderType = 'T' then 'OTH'
				when cod.orderType = 'S' then 'SER'
				else 'EXT'
			end  OrderClassification,


		coalesce 
		(
			case 
				when cod.OrdCodeID in (1698219941708910,1782134180876620) then 'Asthma'
				when cod.OrdCodeID in (1782137855146180,1546982986950550,1698598529808880,1782137855146200) then 'BCCCP'
				when cod.OrdCodeID in (1782128651617460,1566919638951050,1698598529858880) then 'BH'
				when cod.OrdCodeID in (1848583165947840) then 'BHCC'
				when cod.OrdCodeID in (1689668720157420,1782133846854100,1698598529908880) then 'CKD'
				when cod.OrdCodeID in (1541571714500580,1781621187466440) then 'Dental'
				when cod.OrdCodeID in (1692270914009290,1782137855146210,1698219941408910,1548262013000640,1698598529958880,1782138286180760) then 'DiabClinic'
				when cod.OrdCodeID in (1762952242452540) then 'DRE'
				when cod.OrdCodeID in (1698598530008880,1541688197301380,1782133519833000) then 'Dietician'
			end,
			case
				when cod.OrdCodeID in (1782133519833020,1562138939350650) then 'Eligibility'
				when cod.OrdCodeID in (1698598530058880,1698219941608910,1782133846854140) then 'Glucometer'
				when cod.OrdCodeID in (1698598529758880,1782137486120210,1698592302310650,1782137486120190) then 'IM'
				when cod.OrdCodeID in (1541688197251380,1781625743904210) then 'OPT'
				when cod.OrdCodeID in (1782139194248550,1698598530108880,1542202519001000,1782138286180780,1782139194248560,1698598530158880) then 'Patient Assistance'
				when cod.OrdCodeID in (1698598530308880,1541150146550670,1782133519832990) then 'Psych'
				when cod.OrdCodeID in (1698219941508910,1782139194248570,1782139194248590) then 'Peds'
				when cod.OrdCodeID in (1544886745400570,1698598530408880,1746719219380770,1782134180876640) then 'Psycho'
	
			end,
			case
				when cod.OrdCodeID in (1698598530458880,1698219941308910,1782133846854120,1672232184456570) then 'SS'
				when cod.OrdCodeID in (1781620212391710,1541571714400580) then 'WIC'
				when cod.OrdCodeID in (1781618115217790,1776605115544910) then 'Uro-Gyn'
				when cod.OrdCodeID in (1698598530508880,1566919639001050,1782132721799840) then 'Tobacco'
				when cod.OrdCodeID in (1541150145850670,1782138286180800,1782139194248600,1698598530558880) then 'WH'
				when cod.OrdCodeID in (1756897055935160,1782134180876650) then 'HCHP'
				when cod.OrdCodeID in (1687077611506520) then 'HodgePodge'
			end,
			case
				when cod.OrdCodeID in (1687512672556590) then 'CareCoordinator'
				when cod.OrdCodeID in (1833450962243020) then 'Memory'
				when cod.OrdCodeID in (1584962341000760) then 'Nutrition'
				when cod.OrdCodeID in (1687077611556520) then 'OB/GYN'
				when cod.OrdCodeID in (1848841008764370) then 'SubstanceAbuse'
				when cod.OrdCodeID in (1679389536207830,1782133519833040) then 'Surgeon'
			end,
			case 
				when Description like '%mammo%' then 'Mammo'
				when Description like '%xray%' or Description like '%x-ray%' then 'Xray' 
				when Description like '%mri%' then 'MRI' 
				when Description like '%dexa%' then 'Dexa' 
				when Description like 'CT%' or Description like 'HDRS - CT%' then 'CT Scan'
				when Description like 'US%' or Description like 'HDRS - US%' then 'Ultrasound'
				else 'Other'
			end,
			case
				
				when DefaultClassification = 2 then 'Radiology'
				when DefaultClassification = 1 then 'Laboratory'
				when cod.OrdCodeID in (1548262013000640,1698598529958880,1782138286180760) then 'DiabEd'


				else 'Other' 
			end 
		)DefaultClassification,
		one.Total_1Year, two.Total_2Years,five.Total_5Years,
		cod.AUCRequired, cod.AUCOrderCode
	--into #temp
	from [cpssql].centricityps.dbo.ordercodes cod
		left join [cpssql].CentricityPS.dbo.OrderCat cat on cat.OrdCatID = cod.OrdCatID
		left join one_year_hist one on one.OrderCodeID = cod.OrdCodeID
		left join two_year_hist two on two.OrderCodeID = cod.OrdCodeID
		left join five_year_hist five on five.OrderCodeID = cod.OrdCodeID
	where code is not null
		--and cod.OrdCodeStatus = 'a'

	UNION

	select 0, 0, 'Unknown', 'R', 'Unknown',  NULL, NULL, NULL, NULL, NULL, 'N',0, 'Unknown','EXT','Other', null, null,null, null,null

)
--select * from u



insert into [cps_orders].[OrderCodesAndCategories] 
	(
		OrderCodeID, OrderCatID, OrderCode, OrderDesc, OrderPrompt, Duration, 
		DurationUnits, Unit, DefaultClassification, IsTOC,Inactive,CategoryName,
		OrderType,[OrderClassification], Common, Total_1Year, Total_2Years,Total_5Years,
		AUCRequired,AUCOrderCode
	)
select OrderCodeID, OrderCatID, OrderCode, OrderDesc, OrderPrompt, Duration, 
	DurationUnits, Unit, DefaultClassification, IsTOC,Inactive,CategoryName,
	OrderType,[OrderClassification], Common, Total_1Year, Total_2Years,Total_5Years,
	AUCRequired,AUCOrderCode
from u


end

go

