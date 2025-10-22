
use CpsWarehouse
go

drop proc if exists cps_insurance.rpt_CCD_ToInsurance_asDM
go

create proc cps_insurance.rpt_CCD_ToInsurance_asDM
(
	@insurance varchar(50),
	@StartDate date,
	@EndDate date
)

as begin

	--declare @insurance varchar(50) = 'UHC',
	--	@StartDate date = '2020-01-01',
	--	@EndDate date = convert(date, getdate() )

	;with last_billed_visit as (
		select 
			pvt.PID, convert(date, pvt.dos) LastDoS, InsuranceName, pvt.Facility,
			rowNum = ROW_NUMBER() over(partition by pid order by dos desc)
		from cps_all.InsuranceCarriers ic
			left join cps_visits.PatientVisitType pvt on pvt.InsuranceCarrierUsed = ic.InsuranceCarriersID
		where Classify_Major_Insurance = @insurance
			and pvt.DoS >= @StartDate
			and pvt.DoS <= @EndDate
	)
	, last_CVS_sent as (
		select *, rownum = ROW_NUMBER() over(partition by pid order by obsdate desc)
		from cps_obs.DirectMessaging_Sent dm  
		where cvs = 1
	)
		select 
			pp.PatientID, bill.PID, bill.LastDoS, bill.InsuranceName, bill.Facility, Recipient, Subjects, ObsDate CCDDate, 
			case when ObsDate is not null then datediff(day, bill.LastDoS, obsdate) end CVSSentAfter
		from last_billed_visit bill
			left join last_CVS_sent dm on dm.pid = bill.PID and dm.rownum = 1
			left join cps_all.PatientProfile pp on pp.pid = bill.PID
		where bill.rowNum = 1

end 
go
