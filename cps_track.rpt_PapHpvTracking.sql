use CpsWarehouse
go

drop proc if exists cps_track.rpt_PapHpvTracking;
go

create proc cps_track.rpt_PapHpvTracking
(
	@StartDate date,
	@EndDate date
)
as 
begin

	

	select 
		pp.PatientID, pp.Name, pp.DoB, pp.Sex, pp.AgeDecimal, ic.Classify_Major_Insurance, ic.InsuranceName, pp.Facility, pp.Language, 
		pap.lastVisit, pap.lastPAPDate, pap.lastPAPResult, pap.lastHPVDate, pap.lastHPVResult,
		pap.nextApptDate, pap.NextApptWith, yearsSinceLastHPV, yearsSinceLastPAP, pastDue, LastElectronicResult
	from CpsWarehouse.cps_track.papHPVTracking pap
		left join cps_all.PatientProfile pp on pp.pid = pap.PID
		left join cps_all.PatientInsurance ins on ins.pid = pp.PID
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.PrimCarrierID
	where pap.lastVisit >= @StartDate 
		and pap.lastVisit <= @EndDate

end;

go
