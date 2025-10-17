	
	use CpsWarehouse
	go

	drop view if exists [cps_orders].[rpt_view_InternalReferral_Appt];
	go
	
	create view [cps_orders].[rpt_view_InternalReferral_Appt]
	as

	with allref_with_appt as (
		SELECT --top 100 
			o.OrderLinkID ,o.OrderCodeID,o.OrderDesc,  cod.DefaultClassification, o.OrderType,
			o.OrderProvider,
			o.FacilityID, o.Facility,

			o.ClinicalComment,
			case o.CurrentStatus
				when 'H' then 'Admin Hold'
				when 'S' then 'In Process'
				when 'C' then 'Complete'
			end ReferralStatus, 
			o.VisitDate,o.OrderDate,o.CompletedDate,

			o.PID ,o.PatientID,
			pp.Name,pp.DoB,	pp.Phone1, pp.Phone2,
			ic.InsuranceName,
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

			,d.year, d.Month, d.MonthName
	
		FROM cps_orders.Fact_all_orders o
			inner join cps_all.PatientProfile pp on pp.PID  = o.PID
			left join cps_all.PatientInsurance pin on pin.pid = o.pid
			left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pin.PrimCarrierID
			left join dbo.dimDate d on d.Date = o.OrderDate
			INNER JOIN [CpsWarehouse].[cps_orders].OrderCodesAndCategories cod on cod.OrderCodeID = o.OrderCodeID 
																	and cod.OrderClassification = 'INT'
																	and Canceled = 0

			left join [CpsWarehouse].[cps_visits].Appointments ap on ap.PID = o.PID 
																	and ap.ApptDate >= o.OrderDate 
																	and ap.InternalReferral = cod.DefaultClassification
			where o.OrderType = 'R' and o.OrderClassification = 'INT' and pp.TestPatient = 0

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
