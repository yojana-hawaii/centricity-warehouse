use CpsWarehouse

drop proc if exists cps_visits.rpt_PatientPanelPerProvider;
go

create proc cps_visits.rpt_PatientPanelPerProvider
(
	@StartDate date,
	@EndDate date,
	@ProviderName varchar(100)
)
as 
begin
	;with u as (
		select  df.ListName, pvt.PID, max(convert(date,pvt.DoS)) LastProviderVisit
		from cps_visits.PatientVisitType pvt
			left join cps_all.DoctorFacility df on df.DoctorFacilityID = pvt.ApptProviderID
		where dos >= @StartDate
			and dos <= @EndDate
			and df.ListName like '%' + @ProviderName + '%'
		group by ListName,PID
	) 
	, med as (
		select  pvt.PID, max(convert(date,pvt.DoS)) LastMedicalVisit
		from cps_visits.PatientVisitType pvt
		where PID  in (select distinct PID from u)
			and MedicalVisit = 1
		group by PID
	) , bh as (
		select pvt.PID, max(convert(date,pvt.DoS)) LastBHVisit
		from cps_visits.PatientVisitType pvt
		where PID  in (select distinct PID from u)
			and BHVisit = 1
		group by PID
	) , opt as (
		select pvt.PID, max(convert(date,pvt.DoS)) LastOptVisit
		from cps_visits.PatientVisitType pvt
		where PID  in (select distinct PID from u)
			and OptVisit = 1
		group by PID
	) , tele as (
		select pvt.PID, max(convert(date,pvt.DoS)) LastTelehealthVisit
		from cps_visits.PatientVisitType pvt
		where PID  in (select distinct PID from u)
			and Telehealth = 1
		group by PID
	) , en as (
		select pvt.PID,max(convert(date,pvt.DoS)) LastEnablingVisit
		from cps_visits.PatientVisitType pvt
		where PID  in (select distinct PID from u)
			and EnablingVisit = 1
		group by PID
	) , hcpcs as (
		select pvt.PID, max(convert(date,pvt.DoS)) LastHCPCSVisit
		from cps_visits.PatientVisitType pvt
		where PID  in (select distinct PID from u)
			and HCPCS = 1
		group by PID
	) , noq as (
		select pvt.PID, max(convert(date,pvt.DoS)) LastNoQualifierVisit
		from cps_visits.PatientVisitType pvt
		where PID  in (select distinct PID from u)
			and NoQualifier = 1
		group by PID
	)
		select 
			u.ListName Providers,
			pp.Name, pp.PatientID, pp.DoB, pp.Language, pp.Phone1, pp.Phone2, pp.Phone3, pp.PCP, 
			u.LastProviderVisit, med.LastMedicalVisit, bh.LastBHVisit, opt.LastOptVisit, 
			tele.LastTelehealthVisit, en.LastEnablingVisit, hcpcs.LastHCPCSVisit, noq.LastNoQualifierVisit
		from u
			left join cps_all.PatientProfile pp on pp.PID = u.PID
			left join med on u.pid = med.PID
			left join bh on u.pid = bh.PID
			left join opt on u.pid = opt.PID
			left join tele on u.pid = tele.PID
			left join en on u.pid = en.PID
			left join hcpcs on u.pid = hcpcs.PID
			left join noq on u.pid = noq.PID

end
go