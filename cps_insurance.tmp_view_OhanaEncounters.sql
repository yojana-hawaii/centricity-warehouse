
use CpsWarehouse
go


drop view if exists cps_insurance.tmp_view_OhanaEncounters
go
create view cps_insurance.tmp_view_OhanaEncounters
as


	/****** find relevant visit for Ohana Flat File
		has to be Medical BH or optometry visit
		has to have insurance as ohana
		insruance ID cannot be blank since Ohana matches on it
	****************/
	select 
		pv.InsuranceIDUSed InsuranceID, ic.InsuranceName, pv.PID, pv.TicketNumber,
		convert(date, pv.DoS) DoS,
		pv.BilledProviderID, pv.ApptProviderID,
		'11' Location,
		pv.PatientVisitID,
		doc.SDID, pv.PrimaryCPT, pv.CPTCode, pv.ICD10, pv.PrimaryICD, Telehealth
	from cps_visits.PatientVisitType pv
		left join cps_visits.PatientVisitType_Join_Document doc_pv on doc_pv.[PatientVisitID] = pv.PatientVisitID
		left join cps_visits.Document doc on doc.SDID = doc_pv.SDID
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pv.InsuranceCarrierUsed
	where ic.Classify_Major_Insurance = 'ohana'
		and pv.dos >= '2019-01-01'
		--and (pv.MedicalVisit = 1 or pv.BHVisit = 1 or pv.OptVisit = 1) -- immunization may not be in office visit
		and InsuranceIDUSed is not null
		and InsuranceIDUSed not in ('', 'none');


go

