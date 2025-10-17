
use CpsWarehouse
go
drop view if exists cps_visits.tmp_view_apptType;
go
create view cps_visits.tmp_view_apptType
as
	with appt as (
		select 
			app.AppointmentsID AppointmentsID,
			apt.ApptTypeId ApptTypeId,apt.Name Name, apt.Duration Duration,
			case when app.DoctorId =  app.ResourceId then app.DoctorId
				when app.ResourceId is null then app.DoctorId
				else app.ResourceId end DoctorFacilityID
		from [cpssql].CentricityPS.dbo.ApptType apt
			inner join [cpssql].CentricityPS.dbo.Appointments app on apt.ApptTypeId = app.ApptTypeId
			left join [cpssql].CentricityPS.dbo.patientProfile pp on pp.patientID = app.ownerid
		where app.ApptKind = 1 
				and app.ApptStart >= '2017-01-01'
				and pp.last not like 'test%'
	)
		select 
			AppointmentsID, ApptTypeId, Name, Duration, --df.ListName,

			coalesce
			(
				case 
					when Name in ('Diabetes-Group-Visit','Diabetes Consult -30','DM CLASS') then 'Diab_Ed' 
					when Name = 'Diabetes pt - 30' then 'Diab_CC'
					when a.DoctorFacilityID = 698 /*Dr Wang*/ then 'Diab_Clinic'
					when Name = 'DM Clinic Visits' then 'Diab_Clinic'
					when Name like 'Dietitian%' then 'Dietician'

					when Name like 'eye%' then 'OPT'
					when Name in ('Diabetes Retinal Exam' ,'DFE - 15') then 'OPT_DRE' 
				end,
				case
					when Name like '%Asthma%' then 'Asthma' 
					when Name like 'HODGE-PODGE' then 'HodgePodge'
					when Name like 'Memory%' then 'Memory'
					when Name like 'Social Services%' then 'SS'
					when Name like 'Eligibility%' then 'Eligibility'
					when Name like '%CKD%' then 'CKD' 
					when Name like 'BCCCP%' then 'BCCCP'
				end,
				case
					when name like 'er follow%' or name like 'hospital follow%' then 'ER_IP'
					when name like 'same day%' or name = 'Overbook Same Day Appt' then 'Same_Day'

					when name like 'ob f%' then 'OB'
					when name like 'new ob%' then 'OB'
					when name like 'women''s%' then 'WH'
					when name like 'newborn f%' then 'Newborn'
					when name like 'Well Child%' then 'Well_Child'
				end,
				case
					when name like 'interpret%' then 'Interpretation'
					when name like 'TB Shot' then 'TB'
					when name like 'TB Reading' then 'TB'
					when name like 'Immunization%' then 'Immunization'
					when name like 'lab%' then 'Lab'

				end,
				case
					when Name like 'Tobacco%' then 'BH_Tobacco'
					when Name like '%psych%'  then 'BH_Psych'
					when Name like 'BH Care Coordination%' then 'BH_CC'
					when Name like 'BH Consult%' then 'BH_Consult'
					when Name like 'Diag%' then 'BH_Diag'
					when Name like 'Group%' then 'BH_Group'
					when Name like 'Therapy%' then 'BH_Therapy'
					when df.JobTitle in ('Therapist','Psychiatrist','Psychologist') 
							or Name like 'BH%' 
							or Name like 'diag%'
							or Name like 'Thera%'
							or Name like 'group%'
						then 'BH'
					when (
							Name in ('HCH - Community Visit','HCH - Office Visit','HCH - Home Visit','Out of Office - Outreach','HPRP - Walk In') 
							--or JobTitle in ('Case Manager', 'HCHP', 'Outreach', 'CBCM Case Manager', 'HF Case Manager', 'HF housing Specialist')
						)  
						then 'HCHP'
				end
			)InternalReferral
		from appt a
			left join cps_all.[DoctorFacility] df on df.doctorfacilityid = a.DoctorFacilityID

go

