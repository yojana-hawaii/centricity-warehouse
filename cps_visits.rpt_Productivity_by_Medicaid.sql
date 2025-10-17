use CpsWarehouse
go
drop table if exists [cps_visits].[rpt_Productivity_by_Medicaid]
go
create proc [cps_visits].[rpt_Productivity_by_Medicaid]
as
begin

Declare 
	@date date = '2019-12-01';

;with all_tickets as (
	select distinct
		pvt.PID,
		 d.Year, d.MonthName, d.Month, d.DayOfWeek, d.WeekOfMonth, 
		 appt.jobtitle,
		 case 
			when appt.JobTitle in ('Psychologist','Therapist','Psychiatrist' ) then 'BH'
			when appt.JobTitle in ('Optometrist' ) then 'Vision'
			when pvt.MedicalVisit = 1 then 'Medical'
			when pvt.BHVisit = 1 then 'BH'
			when pvt.OptVisit = 1 then 'Vision'
		end CHC_Name
	from cps_visits.PatientVisitType pvt
		left join cps_all.DoctorFacility appt on appt.DoctorFacilityID = pvt.ApptProviderID
		left join dbo.dimDate d on cast(pvt.DoS as date) = d.date
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pvt.InsuranceCarrierUsed
	where pvt.DoS >= @Date
		and pvt.Dos < convert(date, getdate() )
		and appt.ListName is not null
		and (pvt.MedicalVisit = 1 or pvt.BHVisit = 1 or pvt.OptVisit = 1)
		and ic.Classify_Meaningful_Use = 'Medicaid'
)

, byType as (
	select 
		Year, MonthName, month, CHC_Name,
		[1] as Week1, [2] Week2, [3] Week3, [4] Week4, [5] Week5, [6] Week6,
		[1] + [2] + [3] + [4] + [5] + [6] Monthly
	from (
		select 
			year, MonthName, month, CHC_Name,  WeekOfMonth, PID
		from all_tickets
	) q
	pivot (
		count(PID)
		for WeekOfMonth in ([1], [2], [3], [4], [5], [6])
	) as pvt
)

	select * 
	from byType
	order by year, month, CHC_Name

end

go