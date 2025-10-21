use CpsWarehouse
go

drop table if exists [CpsWarehouse].[cps_hchp].CBCMMetricDueNow;
go
create table [CpsWarehouse].cps_hchp.CBCMMetricDueNow (
	[PID] [numeric](19, 0) NULL,
	[Metric] [varchar](20) NOT NULL,
	[PastDue] [bit] NOT NULL
) ON [PRIMARY]

GO

drop PROCEDURE if exists cps_hchp.ssis_CBCMMetricDueNow 
go
create  procedure cps_hchp.ssis_CBCMMetricDueNow
as begin 

with a as (
	select  c.pid, --pp.CaseManager, 
		case c.assessDue when 'Y' then 1 else 0 end Assessment, 
		case c.treatDue when 'Y' then 1 else 0 end Treatment,
		case c.bprsDue when 'Y' then 1 else 0 end BPRS,
		case c.acuityDue when 'Y' then 1 else 0 end Acuity
	from [cps_hchp].cbcm_metric c
		left join cps_all.PatientProfile pp on c.pid = pp.PID
), b as (
	select *, 
		case when a.Assessment = 1  or a.Treatment = 1 or a.BPRS = 1 or a.Acuity = 1 then 1 else 0 end AllMetric 
	from a
) , u as (
	select p.pid, p.Metric, p.PastDue from
	 (select * from b) as t
		unpivot (PastDue for Metric in (Assessment, Treatment, BPRS, Acuity, AllMetric) ) as p
) 
	merge [CpsWarehouse].[cps_hchp].CBCMMetricDueNow as [target]
		using u as [source] on [source].pid = [target].pid and [target].Metric = [Source].Metric
	when matched and (
		 [target].PastDue <> [source].PastDue
	)
	then update set
		[target].PastDue = [source].PastDue
	when not matched by target
		then insert (PID,Metric,PastDue)
		values(PID,Metric,PastDue)
	when not matched by source then delete;

end
GO