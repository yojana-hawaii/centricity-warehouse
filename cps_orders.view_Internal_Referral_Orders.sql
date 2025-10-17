
use CpsWarehouse
go
drop view if exists [cps_orders].[view_InternalReferral_Orders];
go
	create view [cps_orders].[view_InternalReferral_Orders]
	as

	with allref_with_appt as (
	SELECT 
		o.OrderLinkID ,o.OrderCodeID,cod.OrderDesc, cod.DefaultClassification, o.OrderType,
		o.OrderProvider, o.OrderProviderID,
		o.LoC, o.LocID, o.Facility,

		o.ClinicalComment,
		o.CurrentStatus,
		o.VisitDate,o.OrderDate,o.CompletedDate,

		o.PID ,o.PatientID, o.Name,
	
		lower(ap.ApptType) ApptType,
		ap.DoctorFacilityID specialistDoctorID, ap.ListName Specialist,
		ap.AppointmentsID,ap.ApptDate, ap.StartTime, ap.canceled,
		case 
			when ap.Canceled = 1 then 'Cancel'
			when ApptStatus is null then 'No Appt'
			when ApptStatus in ('Arrived','Confirmed','Left Message','No Answer',
						'No Phone','otherEKAMRK031813','Ready for provider','Scheduled')
					and ApptDate < convert(date,getdate())
				then 'Check Appt Status'
			when ApptStatus in ('Arrived','Confirmed','Left Message','No Answer',
						'No Phone','otherEKAMRK031813','Ready for provider','Scheduled')
					and ApptDate >= convert(date,getdate())
				then 'Scheduled'
			else ApptStatus
		end ApptStatus
	
	FROM CpsWarehouse.cps_orders.Fact_all_orders o
		INNER JOIN [CpsWarehouse].[cps_orders].OrderCodesAndCategories cod on cod.OrderCodeID = o.OrderCodeID 
																and cod.OrderClassification = 'INT'
																and Canceled = 0
		left join [CpsWarehouse].cps_visits.Appointments ap on ap.PID = o.PID 
																and ap.ApptDate >= o.OrderDate 
																and ap.InternalReferral = cod.DefaultClassification

	)
	,notCancelled as
	(
		select * from 
		(
			select 
				*, NotCancelled = ROW_NUMBER() over(partition by orderlinkID, PID order by apptStatus asc)
			from allref_with_appt
			where Canceled = 0
		) n
		where n.NotCancelled = 1
	)
	, cancelled as 
	(
		select * from
		(
			select *, CancelOrNotSetup = ROW_NUMBER() over(partition by orderlinkID, PID order by apptStatus asc)
			from allref_with_appt a
			where a.OrderLinkID not in (select OrderLinkID from notCancelled)
		) n
		where n.CancelOrNotSetup = 1
	)
		select * from notCancelled
		union 
		select * from cancelled


	go