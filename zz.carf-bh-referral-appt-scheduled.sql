use CpsWarehouse
go

declare @StartDate date = '2020-01-01', 
	@EndDate date = '2024-01-01',
	@InternalReferral nvarchar(20) =  'BH,PSYCH,PSYCHO,BHCC'


drop table if exists #referralList;
create table #referralList (
	InternalReferral varchar(50)
)

--different query depending on paramter
if (@InternalReferral = 'All')
begin 
	insert into #referralList 
	select distinct DefaultClassification
	from cps_orders.rpt_view_InternalReferral_Appt i
	where i.OrderDate >= @StartDate
		and i.OrderDate <= @EndDate
end else  begin
	insert into #referralList 
	select Item
	from fxn.SplitStrings(@InternalReferral, ',')
end

--select * from #referralList


select 
	i.PatientID, 

	i.DefaultClassification Referral,
	i.OrderDate ReferralDate, 
	i.ReferralStatus,
	f.InProcessDate ReferralInProcessDate,
	f.CompletedDate ReferralCompleteDate,

	app.created ApptCreatedDate,
	i.ApptDate, 
	i.ApptStatus, 
	i.Specialist ApptProvider, 
	f.AdminComment,
	f.ClinicalComment, 

	i.OrderLinkID, 
	i.AppointmentsID, 
	
	i.OrderDesc, 
	
	i.Name, 
	i.DoB, i.Phone1, 
	ic.InsuranceName,
	i.OrderProvider, i.Facility, i.ApptType, 
	i.StartTime, 
	year,month,MonthName
from cps_orders.rpt_view_InternalReferral_Appt i
	left join cps_all.PatientInsurance pin on pin.pid = i.pid
	left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pin.PrimCarrierID
	inner join #referralList r on i.DefaultClassification = r.InternalReferral
	left join cps_visits.Appointments app on app.AppointmentsID = i.AppointmentsID
	left join cps_orders.Fact_all_orders f on f.OrderLinkID = i.OrderLinkID
where i.OrderDate >= @StartDate
	and i.OrderDate <= @EndDate
