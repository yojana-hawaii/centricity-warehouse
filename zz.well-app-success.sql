use CpsWarehouse

go
declare @startDate date ='2022-01-01'
select 'Well Confirmed' ConfirmationStaus, sum(Canceled) Cancelled,  count(*) Total, sum(Canceled)*100/count(*) 'Cancel%'
from cps_visits.ApptCycleType
where WellConfirmed = 1
	and convert(date, ApptDateTime) >= @startDate
	and isnull(CancellationReason,'') not in ('Provider Cancelled Appt','Deceased','Data Entry Error','Cancel/Facility Error')
	and convert(date, ApptCreatedDate) < convert(date, ApptDateTime)

union

select 'Staff Confirmed' ConfirmationStaus, sum(Canceled) Cancelled,  count(*) Total, sum(Canceled)*100/count(*) 'Cancel%'
from cps_visits.ApptCycleType
where WellConfirmed = 0 and ConfirmedBy is not null
	and convert(date, ApptDateTime) >= @startDate
	and isnull(CancellationReason,'') not in ('Provider Cancelled Appt','Deceased','Data Entry Error','Cancel/Facility Error')
	and convert(date, ApptCreatedDate) < convert(date, ApptDateTime)

union
select 'Left Message' ConfirmationStaus, sum(Canceled) Cancelled,  count(*) Total, sum(Canceled)*100/count(*) 'Cancel%'
from cps_visits.ApptCycleType
where WellConfirmed = 0 and ConfirmedBy is  null and LastMessageLeftBy is not null
	and convert(date, ApptDateTime) >= @startDate
	and isnull(CancellationReason,'') not in ('Provider Cancelled Appt','Deceased','Data Entry Error','Cancel/Facility Error')
	and convert(date, ApptCreatedDate) < convert(date, ApptDateTime)

union
select 'Phone Issue' ConfirmationStaus, sum(Canceled) Cancelled,  count(*) Total, sum(Canceled)*100/count(*) 'Cancel%'
from cps_visits.ApptCycleType
where WellConfirmed = 0 and ConfirmedBy is  null and LastMessageLeftBy is null and LastPhoneIssueBy is not null
	and convert(date, ApptDateTime) >= @startDate
	and isnull(CancellationReason,'') not in ('Provider Cancelled Appt','Deceased','Data Entry Error','Cancel/Facility Error')
	and convert(date, ApptCreatedDate) < convert(date, ApptDateTime)
union
select 'No Confirmation' ConfirmationStaus, sum(Canceled) Cancelled,  count(*) Total, sum(Canceled)*100/count(*) 'Cancel%'
from cps_visits.ApptCycleType
where WellConfirmed = 0 and ConfirmedBy is  null and LastMessageLeftBy is  null and LastPhoneIssueBy is  null
	and convert(date, ApptDateTime) >= @startDate
	and isnull(CancellationReason,'') not in ('Provider Cancelled Appt','Deceased','Data Entry Error','Cancel/Facility Error')
	and convert(date, ApptCreatedDate) < convert(date, ApptDateTime)
union
select 'Same Day' ConfirmationStaus, sum(Canceled) Cancelled,  count(*) Total, sum(Canceled)*100/count(*) 'Cancel%'
from cps_visits.ApptCycleType
where WellConfirmed = 0 and ConfirmedBy is  null and LastMessageLeftBy is  null and LastPhoneIssueBy is  null
	and convert(date, ApptDateTime) >= @startDate
	and isnull(CancellationReason,'') not in ('Provider Cancelled Appt','Deceased','Data Entry Error','Cancel/Facility Error')
	and convert(date, ApptCreatedDate) = convert(date, ApptDateTime)

	select  Cancellationreason,count(*) 
	from cps_visits.ApptCycleType 
	where  convert(date, ApptDateTime) >= @startDate and Canceled = 1
		and convert(date, ApptCreatedDate) = convert(date, ApptDateTime)
	group by Cancellationreason


