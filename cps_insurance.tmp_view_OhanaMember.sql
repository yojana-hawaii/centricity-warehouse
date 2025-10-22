
use CpsWarehouse
go

drop view if exists cps_insurance.tmp_view_OhanaMembers;
go
create view cps_insurance.tmp_view_OhanaMembers
as
	select 
		distinct 
		pv.InsuranceIDUSed Member_Subscriber_ID, 
		pp.First Member_FName,
		pp.Last Member_LName,
		pp.Sex Member_Gender,
		pp.Dob Member_BirthDate,
		pv.PID, ic.InsuranceName, pv.InsuranceCarrierUsed
	from cps_visits.PatientVisitType pv
		left join cps_visits.PatientVisitType_Join_Document doc_pv on doc_pv.[PatientVisitID] = pv.PatientVisitID
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pv.InsuranceCarrierUsed
		left join cps_all.PatientProfile pp on pp.pid = pv.PID
	where ic.Classify_Major_Insurance = 'ohana'
		and pv.dos >= '2019-01-01'
		--and (pv.MedicalVisit = 1 or pv.BHVisit = 1 or pv.OptVisit = 1) -- immunization may not be in office visit
		and InsuranceIDUSed is not null
		and InsuranceIDUSed not in  ('', 'none');

go


