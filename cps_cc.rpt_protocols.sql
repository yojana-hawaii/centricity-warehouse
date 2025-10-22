

use CpsWarehouse
go

drop proc if exists cps_cc.rpt_protocols;
go

create proc cps_cc.rpt_protocols
(
	@apptdate date,
	@pvid_str varchar(20)

)

as 
begin

	--declare @apptDate date = convert(date, getdate()), @pvid_str varchar(20) = '1536148802000010';/*Dr. Y*/


	declare @pvid numeric(19,0) = convert( numeric(19,0), @pvid_str)

	
	select 
		ap.PID, pp.PatientID, pp.AgeRounded Age, pp.Sex, pp.Name, 
		case d.DiabType
			when 1 then 1
			when 2 then 2
			when 12 then 12
			else 0
		end DiabetesType, 
		isnull(OsteoporosisM80,0) OsteoporosisM80, 
		isnull(Female16_24,0) Female16_24,
		isnull(Female21_64,0) Female21_64, 
		isnull(Female50_75,0) Female50_75, 
		isnull(All50_75,0) All50_75, 
		isnull(All65Plus,0) All65Plus,

		ap.ApptDate, ap.StartTime, 
		case ap.ApptStatus when 'Confirmed' then 1 else 0 end ApptConfirmed,

		ap.PVID, ap.ListName, loc.Facility,
		n_ap.NextAppt,

		d.LastA1c, d.A1c_DueIn,
		d.LastCreatinine, d.Creatinine_DueIn,
		d.LastLDL, d.LDL_DueIn,
		d.LastMicroalbumin, d.Microalbumin_DueIn,
		d.LastDiabFoot, d.DiabFoot_DueIn,
		d.LastDiabSMG, d.DiabSMG_DueIn,
		d.LastDiabDental, d.DiabDental_DueIn,
		d.LastDiabEye,d.DiabEyeType, d.DiabEye_DueIn,
	 
		a.LastChlamydia, a.Chlamydia_DueIn,
		a.LastPapSmear, a.PapSmear_DueIn,
		a.LastMammogram, a.Mammogram_DueIn,

		a.ColorectalType,a.LastColorectal, a.Colorectal_DueIn,

		a.LastDirective, a.Directive_DueIn, 
		a.LastFunctionalAssess, a.FunctionalAssess_DueIn,

		a.LastFractureQuestion, a.FractureQuestion_DueIn,
		a.LastBoneDensity, a.BoneDensity_DueIn,
		doc.CCDA_Imports, doc.CCDA_Reconcile,
		isnull(er.ER,0) ER, 
		isnull(er.[IP], 0) [IP]
	from cps_visits.Appointments ap
		left join cps_all.Location loc on loc.FacilityID = ap.FacilityID and loc.MainFacility = 1
		left join cps_cc.Protocol_Diabetes d on d.pid = ap.PID
		left join cps_cc.Protocol_Age_Sex a on a.pid = ap.pid
		left join cps_all.PatientProfile pp on pp.PID = ap.pid
		
		left join 
				( 
					select 
						ap.PID, min(ap.ApptDate) NextAppt
					from cps_visits.Appointments ap 
						--inner join cps_all.DoctorFacility df1 on df1.PVID = ap.PVID 
						--			and df1.Billable = 1 
						--			and df1.JobTitle in ('Certified Nurse Midwife','Nurse Practitioner','Physician')
					where ap.Canceled = 0
						and ap.ApptDate > @apptDate
					group by ap.pid
				) n_ap on n_ap.pid = ap.pid 

		left join 
				( 
					select doc.PID, doc.CCDA_Imports, doc.CCDA_Reconcile, max(clinicalDateConverted) LastReport
					from cps_visits.Document doc
					where ccda_imports = 1
							and CCDA_Reconcile != 'C'
							--and clinicalDateConverted >= '2019-01-01'
					group by doc.PID, doc.CCDA_Imports, doc.CCDA_Reconcile

				) doc on doc.pid = pp.pid
		left join 
			(
				select er.PID, 
						max(case when er.ER = 1 then er.[Total for Year] else 0 end) ER,
						max(case when er.ER = 0 then er.[Total for Year] else 0 end) [IP]
				from cps_cc.ER_Count er
				where er.Years = 'PastYear'
				group by PID
			) er on er.PID = pp.PID
	where ap.ApptDate = @apptDate
		and ap.PVID = @pvid_str
		and ap.Canceled = 0

end

go
