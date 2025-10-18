
USE [CpsWarehouse]
GO


drop view if exists [cps_bh].tmp_view_BH_Appointments;
go

create view cps_bh.[tmp_view_BH_Appointments]
as
	SELECT 
		pp.pid,app.ApptDate,app.ApptStatus AS RegistrationStatus,app.Canceled, app.ListName [Provider], app.pvid,
		app.Facility, app.AppointmentsID
	FROM [CpsWarehouse].[cps_visits].Appointments app 
		inner JOIN [CpsWarehouse].[cps_all].PatientProfile pp ON app.PID = pp.pid 
	WHERE 
		app.InternalReferral in ('BH')
		AND app.ApptDate < CONVERT(DATE,GETDATE() )
		and ApptStatus not in ('Data Entry Error','Cancel/Facility Error')
		and pp.TestPatient = 0

	union 

	select 
		pp.pid,app.ApptDate,app.ApptStatus AS RegistrationStatus,app.Canceled, app.ListName [Provider], app.pvid,
		app.Facility, app.AppointmentsID
	FROM [CpsWarehouse].[cps_visits].Appointments app 
		inner JOIN [CpsWarehouse].[cps_all].PatientProfile pp ON app.PID = pp.pid 
		left join cps_all.DoctorFacility df on df.pvid = app.PVID
	where 
		(
			df.JobTitle in ('Psychologist','Therapist','Psychiatrist')
			or df.Specialty in ('Behavioral Health', 'Psychiatry')
		)
		and HomeLocation != 'Kohou'
		AND app.ApptDate < CONVERT(DATE,GETDATE() )
		and ApptStatus not in ('Data Entry Error','Cancel/Facility Error')
		and pp.TestPatient = 0


go
