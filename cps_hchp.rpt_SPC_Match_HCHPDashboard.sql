
go
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_SPC_Match_HCHPDashboard
go
create proc cps_hchp.rpt_SPC_Match_HCHPDashboard
(
	@StartDate date,
	@EndDate date
)
as begin
--declare @startdate date = '2022-01-01', @enddate date = '03-31-2022'

	;with u as (
		select  --psh.PID
			--pvt.TicketNumber,
			-- psh.PSH,
			pp.PatientID, pp.Name, convert(date, pvt.DoS) DoS, --pvt.BilledProvider, df.ListName EnablingResource, pvt.CPTCode, 
			case when agg.OrigInsAllocation > agg.InsPayment then agg.OrigInsAllocation else agg.InsPayment end BillableCharge /*Higher of insurance allocation and insurance payment*/
			--agg.OrigInsAllocation, agg.OrigPatAllocation, agg.InsPayment, agg.PatPayment, agg.InsAdjustment
			--sum(agg.OrigInsAllocation) OrigIns, sum(agg.OrigPatAllocation) OrigPat, sum(agg.InsPayment) InsPay--, sum(agg.PatPayment) PatPay
		from cps_hchp.rpt_view_PSHClients psh	
			left join cps_visits.PatientVisitType pvt on pvt.pid = psh.PID and pvt.DoS >= @StartDate and pvt.DoS <= @EndDate
			left join [cpssql].[CentricityPS].dbo.PatientVisitAgg agg on agg.PatientVisitid = pvt.PatientVisitID
			left join cps_all.DoctorFacility df on df.DoctorFacilityID = pvt.Resource1
			left join cps_all.PatientProfile pp on pp.pid = psh.pid
		where (Valid_PSH_Discharge_Date is null or Valid_PSH_Discharge_Date > @startdate)
			 and psh.pid not in (select distinct PID from cps_hchp.rpt_view_CBCMClients)
			 and dos is not null
			 and (MedicalVisit =1 or BHVisit = 1 or OptVisit = 1)
	)

		select PatientID, Name, Sum(BillableCharge) TotalBillableCharge,	
			STUFF(
				(
					select ', ' + convert(varchar(10),DOS) + ' (' + convert(varchar(10), BillableCharge) + ')'
					from u u1
					where u1.PatientID = u.PatientID
					for xml path ('')
				),1,1,''
			) DoS
		from u
		--where PatientID = 12047577
		group by PatientID, name

end 
go