use CpsWarehouse
go
drop proc if exists [cps_visits].[rpt_Productivity_Number_Issues]
go
create procedure [cps_visits].[rpt_Productivity_Number_Issues]
	(
		@StartDate date,
		@EndDate date
	)
as
begin
--	Declare @StartDate date = '2019-01-01', @EndDate date = '2019-12-31';

select --distinct billingstatus
	convert(date,DoS) DoS, convert(date,BillerEntry) BillerEntry, pvt.TicketNumber, pvt.BillingStatus, pvt.ClaimStatus, pvt.FilingMethod, pvt.FilingType, pvt.BillingDescription ,
		appt.ListName [Provider]
	from cps_visits.PatientVisitType pvt
		left join cps_all.DoctorFacility appt on appt.DoctorFacilityID = pvt.ApptProviderID
		

	where convert(date,pvt.DoS) >= @StartDate
		and convert(date,pvt.DoS) <= @EndDate
		and  (OptVisit = 1 or MedicalVisit = 1 or BHVisit = 1) 
		and 
			(
				ApptProviderConfidence = -1
				or appt.ListName like 'overseer%'
				or convert(date,BillerEntry) < convert(date,DoS)
				--or BillingStatus in ('Filed rejected','Overpaid','Hold','Refund')
			)
		and pvt.Resource1 != 2105


end
go