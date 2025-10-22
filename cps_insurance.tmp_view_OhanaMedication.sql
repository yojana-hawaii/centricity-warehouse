
use CpsWarehouse
go

drop view if exists cps_insurance.tmp_view_OhanaMedication;

go

create view cps_insurance.tmp_view_OhanaMedication
as

select o.PID, o.SDID, o.PatientVisitID, convert(date,ClinicalDate) Service_Date, 'OSTEO' Service_Performed, GenericMed Service_Result, GPI
from cps_insurance.tmp_view_OhanaEncounters o
	inner join cps_meds.PatientMedication m on m.SDID = o.SDID 
where 
	gpi like  '300530%' or gpi like '300420%' or gpi like '300448%' or gpi like '300440%' or gpi like '300445%'
	
	--gpi like '300%'

 
go
