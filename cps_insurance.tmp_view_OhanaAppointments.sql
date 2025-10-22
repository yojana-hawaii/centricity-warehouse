
use CpsWarehouse
go

drop view if exists cps_insurance.tmp_view_OhanaAppointments
go
create view cps_insurance.tmp_view_OhanaAppointments
as
	select
		o.PID, o.PatientVisitID, ap.ApptDate Service_Date, 
		case when ap.ApptType in ('2 Wk PP -15', '6 Wk PP - 15') then 'POST'
			when ap.ApptType in ( 'OB F/UP - 15', 'OB F/UP - 30', 'New OB - 45','New OB - 60') then 'PREN'
		end Service_Provided,
		'Yes' Service_Result, ap.DoctorFacilityID

	from cps_insurance.tmp_view_OhanaEncounters o
		left join cps_visits.Appointments ap on ap.PatientVisitID = o.PatientVisitID
	where ap.ApptType in ('2 Wk PP -15', '6 Wk PP - 15', 'OB F/UP - 15', 'OB F/UP - 30', 'New OB - 45','New OB - 60')
		and ap.Canceled = 0
go

