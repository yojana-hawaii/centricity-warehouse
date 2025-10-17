
use CpsWarehouse
go


drop view if exists [cps_orders].[rpt_view_ExternalReferral]
go

create view [cps_orders].[rpt_view_ExternalReferral]
as
	select  
		o.OrderLinkID,  
		o.PId, o.PatientId, o.Name, 
		o.OrderCodeID, o.OrderCode, o.OrderDesc, o.OrderProvider, o.CurrentStatus, o.Canceled,
		o.OrderDate, o.InProcessDate, o.ReportSource, o.ReportReceivedDate, o.CompletedDate,
		o.Facility, o.FacilityID, o.EndDate,
		r.ReferralSpecialist, 
		isnull(r.ReferralSpecialistid,0) ReferralSpecialistid, 
		r.ReferralApptDate, 
		isnull(r.ReferralRetro,'') ReferralRetro, 
		isnull(r.ReferralStat,'') ReferralStat, 
		isnull(r.ReferralSummaryOfCare,'') ReferralSummaryOfCare, r.ReferralDate,
		case when r.SpecialistCCDA = 1 then r.SpecialistDirectAddress end ElectronicReferral,
		f.FollowupSpecialist, 
		isnull(f.FollowupSpecialistid,0) FollowupSpecialistid, 
		f.FollowupOverdue, f.FollowupReport, f.FollowupComment, f.FollowupDate,
		s.ScannedReport, s.ScanDate, s.Scanned,
		r.TotalReferralAttempt,f.TotalFollowup,
		case 
			when sp.LastName is null and sp.FirstName is null then null
			when sp.LastName is null then sp.FirstName
			when sp.FirstName is null then sp.LastName
			else isnull(sp.LastName, '') + ', ' + isnull(sp.FirstName, '') 
		end 
		+ 
		case when sp.Organization is not null then ' (' + sp.Organization + ')'
		else '' 
		end 
		SpecialistInOrder,
		r.SpecialistContact SpecialistInForm,
		ic.Classify_Major_Insurance, ic.InsuranceName
	from cps_orders.Fact_all_orders o
		left join cps_orders.ReferralSetup r on r.OrderLinkID = o.OrderLinkID
		left join cps_orders.ReferralFollowup f on f.OrderLinkID = o.OrderLinkID
		left join cps_orders.ReferralScanned s on s.OrderLinkID = o.OrderLinkID
		left join cps_orders.OrderSpecialist sp on sp.ServProvID = o.ServProvID and o.ServProvID != 0 
		left join cps_all.PatientInsurance ins on ins.pid = o.pid
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.PrimCarrierID
	where o.OrderType = 'R' 
		--and o.Canceled = 0 
		and o.OrderClassification  in ('EXT')


GO




