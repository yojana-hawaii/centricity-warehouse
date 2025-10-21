USE CpsWarehouse
GO


DROP TABLE if exists [CpsWarehouse].[cps_hchp].[cbcm_metric];
go
CREATE TABLE [CpsWarehouse].[cps_hchp].[cbcm_metric](
	[PID] [numeric](19, 0) NOT NULL,
	[DoS] [date] NOT NULL,
	[VisitType] [varchar](10) NULL,
	[EncounterType] [varchar](12) NULL,
	[iAssess] [varchar](1) NULL,
	[fAssess] [varchar](1) NULL,
	[assessDue] [varchar](1) NOT NULL,
	[iTreat] [varchar](1) NULL,
	[fTreat] [varchar](1) NULL,
	[treatDue] [varchar](1) NOT NULL,
	[iBPRS] [varchar](1) NULL,
	[fBPRS] [varchar](1) NULL,
	[bprsChange] [smallint] NULL,
	[bprsDue] [varchar](1) NOT NULL,
	[iAcuity] [varchar](1) NULL,
	[fAcuity] [varchar](1) NULL,
	[acuityChange] [smallint] NULL,
	[acuityDue] [varchar](1) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_hchp].[ssis_CBCM_Metric] 

go
create procedure [cps_hchp].[ssis_CBCM_Metric]
as begin

truncate table cps_hchp.cbcm_metric;

drop table if exists #CBCMClient
select PID 
into #CBCMClient 
from  cps_hchp.rpt_view_CBCMClients pp 
where cbcm = 1


drop table if exists #cbcmVisitData
--All CBCM data - visits (face to face, collateral and type (amhd,ccs,enabling and dischange)
select pp.pid, ObsDate Obsdate,
	MAX(CASE WHEN HDID = 66473 THEN OBSVALUE END )  VisitType,
	MAX(CASE WHEN HDID = 298426 THEN OBSVALUE END )  EncounterType,
	LastVisit = row_number() over (partition by pp.pid order by obsdate desc)
into #cbcmVisitData
from #CBCMClient pp
	left  join [cpssql].[CentricityPS].[dbo].OBS on (obs.pid = pp.pid and obs.HDID IN (298426,66473) )
group by pp.PID,OBSDATE
--	select * from #cbcmVisitData

drop table if exists #assessment
select pp.PID, obs.obsdate ObsDate, obs.obsvalue ObsValue, 
	Oldest = ROW_NUMBER() OVER (PARTITION BY pp.PID ORDER BY obsdate asc),
	Newest = ROW_NUMBER() OVER (PARTITION BY pp.PID ORDER BY obsdate Desc)
into #assessment
from #CBCMClient pp
	left join [cpssql].centricityps.dbo.obs on obs.pid = pp.pid and obs.hdid = 457781

--	select * from #assessment

drop table if exists #treatment
select pp.PID, obs.obsdate ObsDate, obs.obsvalue ObsValue, 
	Oldest = ROW_NUMBER() OVER (PARTITION BY pp.PID ORDER BY obsdate asc),
	Newest = ROW_NUMBER() OVER (PARTITION BY pp.PID ORDER BY obsdate Desc)
into #treatment
from #CBCMClient pp
	left join [cpssql].centricityps.dbo.obs on obs.pid = pp.pid and obs.hdid = 62718

drop table if exists #bprs_count
select pp.PID, obs.obsdate ObsDate, obs.obsvalue ObsValue, 
	Oldest = ROW_NUMBER() OVER (PARTITION BY pp.PID ORDER BY obsdate asc),
	Newest = ROW_NUMBER() OVER (PARTITION BY pp.PID ORDER BY obsdate Desc)
into #bprs_count
from #CBCMClient pp
	left join [cpssql].centricityps.dbo.obs on obs.pid = pp.pid and obs.hdid = 40773

drop table if exists #acuity_count
select pp.PID, obs.obsdate ObsDate, obs.obsvalue ObsValue, 
	Oldest = ROW_NUMBER() OVER (PARTITION BY pp.PID ORDER BY obsdate asc),
	Newest = ROW_NUMBER() OVER (PARTITION BY pp.PID ORDER BY obsdate Desc)
into #acuity_count
from #CBCMClient pp
	left join [cpssql].centricityps.dbo.obs on obs.pid = pp.pid and obs.hdid = 462650


drop table if exists #first_last_metric
select 
	pp.pid, v.obsdate VisitDate, v.VisitType, v.EncounterType, 
	(case VisitType when 'discharge' then 1 else 0 end) discharged,
	a1.obsDate iAssessdate, a1.Obsvalue iAssess,
	a2.obsDate fAssessdate, a2.Obsvalue fAssess,
	t1.obsDate iTreatDate, t1.Obsvalue iTreat,
	t2.obsDate fTreatDate, t2.Obsvalue fTreat,
	b1.obsDate iBprsDate, b1.Obsvalue iBPPRS,
	b2.obsDate fBprsDate, b2.Obsvalue fBPRS,
	c1.obsDate iacuityDate, c1.Obsvalue iAcuity,
	c2.obsDate fAcuitDate, c2.Obsvalue fAcuity
into #first_last_metric
from #CBCMClient pp
	left join #cbcmVisitData v on v.pid = pp.pid and v.LastVisit = 1
	left join #assessment a1 on a1.pid = pp.pid and a1.Oldest = 1
	left join #assessment a2 on a2.pid = pp.pid and a2.Newest = 1
	left join #treatment t1 on t1.pid = pp.pid and t1.Oldest = 1
	left join #treatment t2 on t2.pid = pp.pid and t2.Newest = 1
	left join #bprs_count b1 on b1.pid = pp.pid and b1.Oldest = 1
	left join #bprs_count b2 on b2.pid = pp.pid and b2.Newest = 1
	left join #acuity_count c1 on c1.pid = pp.pid and c1.Oldest = 1
	left join #acuity_count c2 on c2.pid = pp.pid and c2.Newest = 1


;with u as (
select a.PID, 
	case when VisitDate is not null then convert(date,a.visitDate) else convert(date, a.fAcuitDate) end DoS, 
	a.VisitType, a.EncounterType, 
	--a.discharged, 
	--a.iAssessdate, a.iAssess, 
	case when iAssessdate is not null then 'Y' else 'N' end iAssess,
	--a.fAssessdate, a.fAssess,
	case when a.fAssessdate is not null and a.fAssessdate != a.iAssessdate then 'Y' else 'N' end fAssess,
	case when a.discharged = 1 or datediff(dd, a.fAssessDate, getdate() ) < 180 then 'N' else 'Y' end assessDue,
	--a.iTreat, a.iTreatDate, 
	case when a.iTreatDate is not null then 'Y' else 'N' end iTreat,
	--a.fTreat, a.fTreatDate,
	case when a.fTreatDate is not null and a.fTreatDate != a.iTreatDate then 'Y' else 'N' end fTreat,
	case when a.discharged = 1 or datediff(dd, a.ftreatDate, getdate() ) < 180 then 'N' else 'Y' end treatDue,
	--a.iBPPRS, a.iBprsDate, 
	case when a.iBprsDate is not null then 'Y' else 'N' end iBPRS,
	--a.fBPRS, a.fBprsDate,
	case when a.fBprsDate is not null and a.fBprsDate != a.iBprsDate then 'Y' else 'N' end fBPRS,
	case when a.discharged = 1 or datediff(dd, a.fBprsDate, getdate() ) < 180 then 'N' else 'Y' end bprsDue,
	case when a.fBPRS is not null and b.obsvalue is not null then convert(smallint, a.fBPRS) - convert(smallint, b.obsvalue) end bprsChange,
	--a.iAcuity, a.iacuityDate, 
	case when a.iacuityDate is not null then 'Y' else 'N' end iAcuity,
	--a.fAcuity, a.fAcuitDate,
	case when a.facuitDate is not null and a.fAcuitDate != a.iacuityDate then 'Y' else 'N' end fAcuity,
	case when a.discharged = 1 or datediff(dd, a.fAcuitDate, getdate() ) < 180 then 'N' else 'Y' end acuityDue,
	case when a.fAcuity is not null and c.obsvalue is not null then convert(smallint,a.facuity) - convert(smallint, c.obsvalue) end acuityChange
from #first_last_metric a
	left join #bprs_count b on b.pid = a.pid and b.Newest = 2
	left join #acuity_count c on c.pid = a.pid and c.Newest = 2
where a.VisitDate is not null and a.fAcuitDate is not null
) 
--select * from u

 insert into cps_hchp.cbcm_metric (PID,DoS,VisitType,EncounterType,iAssess,fAssess,assessDue,
	iTreat,fTreat,treatDue,iBPRS,fBPRS,bprsChange,bprsDue,iAcuity,fAcuity,acuityChange,acuityDue)
select PID,DoS,VisitType,EncounterType,iAssess,fAssess,assessDue,
	iTreat,fTreat,treatDue,iBPRS,fBPRS,bprsChange,bprsDue,iAcuity,fAcuity,acuityChange,acuityDue
from u

end


GO
