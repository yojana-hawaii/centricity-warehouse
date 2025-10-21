

go 
use CpsWarehouse
go

drop view if exists cps_hchp.rpt_view_hchpDemographics;

go

create view cps_hchp.rpt_view_hchpDemographics
as
	
		select 
			h.*, 
			pp.PatientID ,pp.Last, pp.First, pp.DoB, pp.Name,
			pp1.Address1, pp1.Address2, pp1.City, 
			pp.Zip, pp.Phone1, pp.Phone2, pp.Phone3,
			pp.Therapist, pp.Psych, pp.ExternalProvider,
			prim.InsuranceName PrimaryInsurance, sec.InsuranceName SecondaryInsurance
		from cps_hchp.HCHP_LastClientStatus h
			left join cps_all.PatientProfile pp on pp.pid = h.pid
			left join cpssql.CentricityPS.dbo.PatientProfile pp1 on pp1.pid = pp.PID
			left join cps_all.PatientInsurance ins on ins.PID = pp.PID
			left join cps_all.InsuranceCarriers prim on prim.InsuranceCarriersID = ins.PrimCarrierID
			left join cps_all.InsuranceCarriers sec on sec.InsuranceCarriersID = ins.SecCarrierID

go
