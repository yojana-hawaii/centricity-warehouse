
use CpsWarehouse
go


drop proc if exists cps_track.Yearly_Telehealth_By_Site

go

create proc cps_track.Yearly_Telehealth_By_Site
(
	@StartDate date,
	@EndDate date
)
as
begin

--declare @startdate date = '2020-01-01', @endDate date = '2020-12-31';
with u as (
	select 
		case when MedicalVisit =1 then 'Medical'
			when BHVisit = 1 then 'BH' 
			when OptVisit = 1 then 'Optometry'
			else 'Other' end VisitType, 
		loc.Facility
	from cps_visits.PatientVisitType pvt
		left join cps_all.Location loc on pvt.FacilityID = loc.FacilityID and loc.MainFacility = 1
	where dos >= @StartDate
		and dos <= @EndDate
		and pvt.Telehealth = 1
)
	select 
		p.Facility, p.Medical, p.BH, p.Optometry, p.Other,
		p.Medical + p.BH + p.Optometry + p.Other Total
	from
	(
		select Facility, VisitType
		from u
	) t
	pivot 
		(
			count(VisitType)
			for VisitType in ([Medical], [BH], [Optometry], [Other])
		) p


end

go
