
use CpsWarehouse
go

drop proc if exists cps_track.Yearly_Telehealth_Details

go

create proc cps_track.Yearly_Telehealth_Details
(
	@StartDate date,
	@EndDate date
)
as
begin

--	declare @startdate date = '2020-01-01', @endDate date = '2020-12-31';
with u as (
	select 
		pp.PatientID,
		--pvt.Telehealth,
		case when MedicalVisit =1 then 'Medical'
			when BHVisit = 1 then 'BH' 
			when OptVisit = 1 then 'Optometry'
			else 'Other' end VisitType, 
		convert(date,pvt.DoS) DoS,
		dt.MonthName,
		loc.Facility,
		df.ListName Providers, pvt.CPTCode, pvt.ICD10
	from cps_visits.PatientVisitType pvt
		left join cps_all.Location loc on pvt.FacilityID = loc.FacilityID and loc.MainFacility = 1
		left join cps_all.PatientProfile pp on pp.pid = pvt.PID
		left join cps_all.DoctorFacility df on df.DoctorFacilityID = pvt.ApptProviderID
		left join dbo.dimDate dt on dt.date = convert(date,pvt.DoS)
	where dos >= @StartDate
		and dos <= @EndDate
		and pvt.Telehealth = 1
) 
	select * from u


end

go
