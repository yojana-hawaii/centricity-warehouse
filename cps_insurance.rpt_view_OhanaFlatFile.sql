
use CpsWarehouse
go

drop view if exists cps_insurance.rpt_view_Ohana_FlatFile;
go
create view cps_insurance.rpt_view_Ohana_FlatFile
as
	with ohana_results as (
		select 
			'service' ohana_type, PID, SDID, Service_Performed, Service_Result, Service_Date , null doctorFacility
			--'' CPTCode, '' Diagnosis2, '' CVXCode, Null doctorFacility, null 
		from cps_insurance.Ohana_Services o
		union all
		select 
			'immunization' ohana_type, PID, SDID, Service_Performed, Service_Result, Service_Date,DoctorFacilityID
			--'' CPTCode, '' Diagnosis2, CVXCode, , null PatientVisitID
		from cps_insurance.tmp_view_Ohana_Immunization o
		where o.Service_Performed is not null
		union all
		select 
			'labs & referrals' ohana_type,  PID, null SDID, Service_Performed, Service_Result, Service_Date, DoctorFacilityID
			--'' CPTCode, '' Diagnosis2, '' CVXCode, , null PatientVisitID
		from cps_insurance.Ohana_Labs_Referrals o
		union all
		select 
			'cpt & ICD' ohana_type, o.PID, SDID, Service_Performed, 'Yes' Service_Result, Service_Date , Null doctorFacility
			--isnull(o.CPTCode,'') CPTCode, o.ICD10Code Diagnosis2, '' CVXCode, NULL ResultDate, null doctorFacilityID, PatientVisitID
		from cps_insurance.Ohana_CPT_ICD o
		--union all
		--select 
		--	'Meds' Ohana_type, o.PID, o.SDID, o.Service_Performed, 'Yes' Service_Result, Service_Date, Null doctorFacility
		--	--'' CPTCode, '' Diagnosis2, '' CVXCode, NULL ResultDate, Null doctorFacility, PatientVisitID
		--from cps_insurance.tmp_view_OhanaMedication o
		union all
		select 'Appt', PID, null SDID, Service_Provided, Service_Result, Service_Date, DoctorFacilityID
		from cps_insurance.tmp_view_OhanaAppointments

		union all
		select 
			'all visits', o.pid, o.SDID, 'AMB' Service_Performed, 'Yes' Service_Result, o.DoS Service_Date, Null doctorFacility
			--'' CPTCode, '' Diagnosis2, '' CVXCode, o.DoS ResultDate, PatientVisitID
		from cps_insurance.tmp_view_OhanaEncounters o

	)
	, demographics as (
		/*Patient & Provider Info*/
		select distinct
				doc.pid, doc.SDID, 
				doc.InsuranceID Member_Subscriber_ID, 
				pp.Member_FName, 
				pp.Member_LName, 
				pp.Member_Gender, 
				pp.Member_BirthDate,
				'' Provider_FName,
				'clinic' Provider_LName,
				'' Provider_NPI,
				'FQHC' OhanaSpecialty,
				doc.DoS Service_date, /*Services, CPT & ICD - immunization and lab & referral may have different*/
				doc.PatientVisitID,
				doc.PrimaryICD Diagnosis1, doc.BilledProviderID
			from cps_insurance.tmp_view_OhanaEncounters doc
				inner join cps_insurance.tmp_view_OhanaMembers pp on pp.pid = doc.PID
				--inner join cps_insurance.tmp_view_OhanaProviders df on df.DoctorFacilityID = doc.BilledProviderID
			
	) 
	,  u as (
		select 
			o.PID, o.SDID, o.ohana_type,d.year, d.month, d.monthname, d.Quarter,
			case when enc.Member_Subscriber_ID is null then mem.Member_Subscriber_ID else enc.Member_Subscriber_ID end Member_Subscriber_ID, 
			case when enc.Member_FName is null then mem.Member_FName else enc.Member_FName end Member_FName, 
			case when enc.Member_LName is null then mem.Member_LName else enc.Member_LName end Member_LName, 
			'' Member_SSN, 
			case when enc.Member_Gender is null then mem.Member_Gender else enc.Member_Gender end Member_Gender, 
			'' Medicare_Num, 
			'' Medicaid_Num, 
			case when enc.Member_BirthDate is null then mem.Member_BirthDate else enc.Member_BirthDate end Member_BirthDate, 

			'' Provider_FName, 
			case 
				when Service_Performed in ('CHL','UMICRO', 'HBA','LDL','FOBT','BLS','CCS') then ''
				else 'in-house' 
			end Provider_LName, 
			case 
				when Service_Performed in ('CHL','UMICRO', 'HBA','LDL','FOBT','BLS','CCS') then ''
				else '1457304966'
			end Provider_NPI, 
			
			case 
				when Service_Performed in ('CHL','UMICRO', 'HBA','LDL','FOBT','BLS','CCS') then 'LAB'
				else 'FQHC' 
			end Provider_Specialty, 
			case 
				when Service_Performed in ('CHL','UMICRO', 'HBA','LDL','FOBT','BLS','CCS') then '81' 
				when Service_Performed in ('OMW','Colon','BCS') then '22'
				when Service_Performed in ('TRC') then '50'
				else '11'
			end Place_Of_Service,

			case when o.Service_date is not null then o.Service_date else enc.Service_date end Service_Date,
			
			Service_Performed,
			Service_Result
	
		from ohana_results o
			left join demographics enc on  enc.SDID = o.SDID --or enc.PatientVisitID = o.PatientVisitID
			--left join demographics enc2 on  enc2.PatientVisitID = o.PatientVisitID
			left join cps_insurance.tmp_view_OhanaMembers mem on mem.pid = o.PID
			left join cps_insurance.tmp_view_OhanaProviders prov on prov.DoctorFacilityID = o.doctorFacility
			left join dbo.dimDate d on d.date = case when o.Service_date is not null then o.Service_date else enc.Service_date end

	)
	select distinct * 
	from u
	where Member_Subscriber_ID is not null /*probably means nothing was billed for this member yet??*/
		--and Provider_FName is not null;
go

