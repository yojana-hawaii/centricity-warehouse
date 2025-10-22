
use CpsWarehouse
go

drop proc if exists cps_insurance.rpt_Appointment_Summary_ByInsurance
go 
create proc cps_insurance.rpt_Appointment_Summary_ByInsurance
(
	@Insurance nvarchar(20),
	@Year int,
	@Quarter int
)
as 
begin

--	DECLARE  @insurance nvarchar(20) = 'alohacare', @year int = 2021, @quarter int = 1;

	declare @major_insurance varchar(30) = case when @Insurance = 'All' then null else @Insurance end;
	;with all_appt as (
		SELECT distinct
			pp.PID,
			--ic.InsuranceName,
			a.ApptDate,
			a.Canceled,
			case when a.ApptType like '%same day%' then 1 else 0 end SameDay,
			d.year, d.Month, d.MonthName, d.Quarter
		  FROM CpsWarehouse.cps_all.PatientProfile pp
			left join CpsWarehouse.cps_visits.Appointments a on a.pid = pp.pid
			left join CpsWarehouse.cps_all.PatientInsurance ins on ins.PID = pp.PID
			left join CpsWarehouse.cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.PrimCarrierID
			left join dbo.dimDate d on d.Date = a.ApptDate
		  WHERE 
			  ic.Classify_Major_Insurance = isnull(@major_insurance, ic.Classify_Major_Insurance)
			  and a.ApptStatus NOT IN ('Cancel/Facility Error','Data Entry Error')
			  and year =  @year
			  and Quarter = @quarter
	) 
	,total as (
		select year, MonthName, Quarter, month, count(*) TotalAppt, sum(convert(tinyint, Canceled)) TotalCancel
		from all_appt
		group by year, MonthName, Quarter, month
	)
	,total_quarterly as (

		select year,  Quarter,  count(*) TotalAppt, sum(convert(tinyint, Canceled)) TotalCancel
		from all_appt
		group by year,  Quarter
	)

	, sameday as (
		select year, MonthName, Quarter, month, count(*) SameDayAppt, sum(convert(tinyint, Canceled)) SameDayCancel
		from all_appt
		where SameDay = 1
		group by year, MonthName, Quarter, month
	)
	, sameday_quarterly as (
		select year,  Quarter, count(*) SameDayAppt, sum(convert(tinyint, Canceled)) SameDayCancel
		from all_appt
		where SameDay = 1
		group by year,  Quarter
	)


		select *
		from (
			select 
				t.Year, t.Quarter, t.Quarter Ordering, t.MonthName, t.Month, 
				t.TotalAppt, t.TotalCancel, 
				t.TotalAppt - t.TotalCancel TotalCheckout, 
				s.SameDayAppt, s.SameDayCancel, 
				s.SameDayAppt - s.SameDayCancel SameDayCheckout
			from total t
				left join sameday s on s.year = t.Year and s.Month = t.Month

			union

				select 
				t.year, t.quarter, t.Quarter + 0.5 ORdering, 'Q' + convert(varchar(1), t.Quarter) MonthName,  t.Quarter   Month, 
				t.TotalAppt, t.TotalCancel, 
				t.TotalAppt - t.TotalCancel TotalCheckout, 
				s.SameDayAppt, s.SameDayCancel, 
				s.SameDayAppt - s.SameDayCancel SameDayCheckout
			from total_quarterly t
				left join sameday_quarterly s on s.year = t.Year and s.Quarter = t.Quarter

		) q

end

go
