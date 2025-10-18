
use CpsWarehouse
go
drop view if exists cps_hl7.view_hdrs_mapping
go
create view cps_hl7.view_hdrs_mapping
as 


select 
	lab.Coding_System, lab.Ext_Result_Code,lab.Ext_Result_Description,
	lab.HDID, lab.ObsTerm,  
	--lab.LoincCode, lab.MLCode,
	pp.PatientID, pp.Name, doc.DocAbbr, doc.ClinicalDateConverted,
	lab.TotalUsed
from CpsWarehouse.cps_hl7.all_HL7_Mapping lab
	left join CpsWarehouse.cps_all.PatientProfile pp on pp.pid = lab.LastPID
	left join CpsWarehouse.cps_visits.Document doc on doc.SDID = lab.LastSDID
where lab.Coding_System = 'HDRS'
	and name not like 'test%'


go