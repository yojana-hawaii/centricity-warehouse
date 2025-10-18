
use CpsWarehouse
go

--create view cps_meds.[view_Medication]
--as


select * ,
	(
		select count(MID)
		from cps_meds.PatientMedication m2
		where m1.pid = m2.pid and m2.Inactive = 0
	) ActiveMedicationCount
from cps_meds.PatientMedication m1


go