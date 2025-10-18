
USE CpsWarehouse
GO


drop table if exists [CpsWarehouse].[cps_bh].[BH_SbirtObs];
go
create table [CpsWarehouse].[cps_bh].[BH_SbirtObs] (
	[SDID] [numeric](19, 0) NOT NULL,
	[OrderProvider] varchar(50) NOT NULL,
	[PID] [numeric](19, 0) NOT NULL,
	[HDID] int not null,
	[ObsTerm] varchar(50) not null,
	[ObsDate] [date] NOT NULL,
	[ObsValue] [varchar](15) NOT NULL,
	[Loc] [varchar](10) NOT NULL,
)

GO

drop PROCEDURE if exists  [cps_bh].[ssis_BH_SbirtObs] 
go
CREATE procedure [cps_bh].[ssis_BH_SbirtObs]
as begin

truncate table [cps_bh].[BH_SbirtObs];


drop table if exists #select_hdid;
select HDID, ObsTerm, TotalUsed
into #select_hdid
from cps_obs.ObsHead 
where ObsTerm in ('AUDITSCORE', 'DAST-10TOTAL');


; with u as (
	select 
		obs.sdid SDID, df.ListName OrderProvider, obs.PID PID,
		s.HDID, s.ObsTerm, convert(date,obs.obsdate) obsdate, obs.obsvalue obsvalue,
		doc.LoC
	from cpssql.CentricityPS.dbo.obs
		inner join #select_hdid s on s.hdid = obs.hdid
		inner join cps_visits.Document doc on doc.SDID = obs.sdid
		left join cps_all.DoctorFacility df on df.PVID = obs.pubuser
	where obs.xid = 1000000000000000000
		and obs.pubuser != 0
		and change not in (10, 11, 12)
)

insert into [cps_bh].[BH_SbirtObs] ([SDID],OrderProvider,[PID], HDID, ObsTerm ,ObsDate, obsvalue,Loc)
select [SDID],OrderProvider,[PID], HDID, ObsTerm ,ObsDate, obsvalue,Loc from u;

end
GO
