
use CpsWarehouse
go


drop proc if exists cps_track.Yearly_Telehealth_By_Month

go

create proc cps_track.Yearly_Telehealth_By_Month
(
	@StartDate date,
	@EndDate date
)
as
begin

--	declare @startdate date = '2020-01-01', @endDate date = '2020-12-31';
with u as (
	select 
		dt.Year,dt.MonthName Month,
		case when MedicalVisit =1 then 'Medical'
			when BHVisit = 1 then 'BH' 
			when OptVisit = 1 then 'Optometry'
			else 'Other' end VisitType, 
		convert(date,pvt.DoS) DoS,
		pvt.pid	
	from cps_visits.PatientVisitType pvt
		--left join cps_all.PatientProfile pp on pp.pid = pvt.PID
		--left join cps_all.DoctorFacility df on df.DoctorFacilityID = pvt.ApptProviderID
		left join dbo.dimDate dt on dt.date = convert(date,pvt.DoS)
	where dos >= @StartDate
		and dos <= @EndDate
		and pvt.Telehealth = 1
) --select distinct Month from u
	select 
		Year, VisitType,
		[January],[February],[March],[April],[May],[June],[July],[August],[September],[October],[November],[December],
		[January]+[February]+[March]+[April]+[May]+[June]+[July]+[August]+[September]+[October]+[November]+[December] Year_Total
	from
	(
		select Year,Month, VisitType
		from u
	) t
	pivot 
		(
			count([Month])
			for [Month] in ([January],[February],[March],[April],[May],[June],[July],[August],[September],[October],[November],[December])
		) p


end

go
