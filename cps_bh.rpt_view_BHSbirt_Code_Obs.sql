
use CpsWarehouse
go

drop view if exists cps_bh.rpt_view_BHSbirt_Code_Obs;
go

create view cps_bh.rpt_view_BHSbirt_Code_Obs
as 


select  
		 o.pid, o.OrderProvider,
		case 
			when o.OrderCode = 'SACR' then 'Outpatient Substance abuse'
			when o.OrderCode = 'SAR' then 'Substance Abuse Residential'
			when o.OrderCode = 'SAMAT' then 'Substance Abuse Outpatient/MAT'
			when o.OrderCode = 'SA' then 'Substance Abuse'
			when o.OrderCode = 'INTSBIRT' then 'Internal Sbirt - 14 min or less'
			else o.OrderCode
		end BH_Metric,
		d.Month, d.MonthName, d.Year, d.Quarter, d.Date, pp.PatientID
	from  cps_orders.Fact_all_orders o
		inner join dbo.dimDate d on d.date = o.OrderDate
		left join cps_all.PatientProfile pp on pp.pid = o.pid
	where 
		o.OrderCode in (
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
	
	union 
	
	select 
		o.PID, o.OrderProvider,
		case ObsTerm when 'AUDITSCORE' then 'Form - Audit > 7' when 'DAST-10TOTAL' then 'Form - Dast > 2' end BHMetric,  
		Month, MonthName, Year, Quarter, d.Date, pp.PatientID
		--, ObsValue
	from cps_bh.BH_SbirtObs o
	inner join dbo.dimDate d on d.date = o.ObsDate
		left join cps_all.PatientProfile pp on pp.pid = o.pid
	where pp.TestPatient = 0
		and ObsValue > case  obsterm when 'AUDITSCORE' then 7  when  'DAST-10TOTAL' then 2 end
	union

	select 
		pvt.pid, pvt.OrderProvider,
		'Form - Audit > 7 and Dast > 2' BHMetric,
		Month, MonthName, Year, Quarter, Date, PatientID
	from (
		select 
			o.PID, obsdate, obsterm,OrderProvider,
			Month, MonthName, Year, Quarter, d.Date
			, convert(varchar(3), ObsValue) ObsValue, pp.PatientID
		from cps_bh.BH_SbirtObs o
			inner join dbo.dimDate d on d.date = o.ObsDate
			left join cps_all.PatientProfile pp on pp.pid = o.pid
		where pp.TestPatient = 0
		and ObsValue > case  obsterm when 'AUDITSCORE' then 7  when  'DAST-10TOTAL' then 2 end
	) q
	pivot (
		max (ObsValue)
		for obsterm in ([AUDITSCORE], [DAST-10TOTAL])
	) pvt
	where isnull(pvt.AUDITSCORE, 0) > 7 and isnull(pvt.[DAST-10TOTAL], 0) > 2


go
