use CpsWarehouse
go


drop proc if exists cps_track.rpt_MammoTracking;
go

create proc cps_track.rpt_MammoTracking 
(
	@StartDate date,
	@EndDate date
)
as
begin

select 
	r.name, r.PatientID, pp.DoB, pp.AgeDecimal, 
	OrderDesc, OrderProvider, r.Facility, 
	VisitDate, InProcessDate, ReportReceivedDate ResultDate, CompletedDate, r.CurrentStatus,
	doc.Summary DocumentSummary, doc.ClinicalDateConverted, doc.LinkLogicSource, ic.Classify_Major_Insurance
from cps_orders.rpt_view_Radiology r
	left join cps_all.PatientProfile pp on pp.pid = r.pid	
	left join cps_visits.Document doc on doc.SDID = r.ResultSDIDList1
	left join cps_all.PatientInsurance ins on ins.PID =pp.PID
	left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.PrimCarrierID
where r.VisitDate >= @StartDate
	and r.VisitDate <=@EndDate
	and 
		 (
			orderdesc  like '%mammo%' 
			or orderdesc in ('US, Breast, bilateral or unilateral','US Guided Biopsy, Breast','MRI Breast Unilateral with and/or without contrast ')
		)
		--and LinkLogicSource like 'hdrs%'

end

go

