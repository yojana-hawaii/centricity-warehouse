

USE CpsWarehouse
GO

drop table if exists [CpsWarehouse].[cps_bh].[BH_SbirtCodes];
go
create table [CpsWarehouse].[cps_bh].[BH_SbirtCodes] (
	[SDID] [numeric](19, 0) NOT NULL,
	[OrderProvider] varchar(50) NOT NULL,
	[PID] [numeric](19, 0) NOT NULL,
	[OrderDate] [date] NOT NULL,
	[OrderCode] [varchar](15) NOT NULL,
	[OrderDesc] [varchar](100) NULL,
	[Loc] [varchar](10) NOT NULL,
)

GO

drop PROCEDURE if exists  [cps_bh].[ssis_BH_SbirtCodes] 
go
CREATE procedure [cps_bh].[ssis_BH_SbirtCodes]
as begin

truncate table [cps_bh].[BH_SbirtCodes];

with u as (
	select 
		o.sdid SDID,  o.OrderProvider , o.pid PID,  
		convert(date,o.orderdate) OrderDate, o.OrderDesc, o.OrderCode,  o.LoC
	from CpsWarehouse.cps_orders.Fact_all_orders o
		left join CpsWarehouse.cps_all.PatientProfile pp on pp.pid = o.pid
	where o.OrderCode in 
			(
				'cpt-99408', 'cpt-99409', /*Sbirt commercial & Medicaid*/
				'cpt-G0396', 'cpt-G0397', /*Sbirt Medicare*/
				'cpt-G0442', /*Sbirt annual alcohol screening*/
				'cpt-H0049', /*sbirt alcohol screening*/
				'cpt-H0050', /*sbirt alcohol intervention*/
				'SACR', /*Outpatient Substance abuse*/
				'SAR',	/*Substance Abuse Residential*/
				'SAMAT',	/*Substance Abuse Outpatient/MAT*/
				'SA', /*Substance Abuse*/
				'INTSBIRT' /*Sbirt 14 min or less - not in production*/
			)
		and pp.TestPatient = 0
		and pp.PatientActive = 1
		and o.CurrentStatus = 'C'

)
--select * from u

insert into [cps_bh].[BH_SbirtCodes] ([SDID],OrderProvider,[PID],[OrderDate],OrderCode,OrderDesc,Loc)
select [SDID],OrderProvider,[PID],[OrderDate],OrderCode,OrderDesc,Loc from u;

end
GO









