

go
use CpsWarehouse
go

drop table if exists cps_hchp.HCHP_LastClientStatus;

go

create table cps_hchp.HCHP_LastClientStatus(
	PID numeric(19,0) not null,
	cbcm varchar(200) null,
	Last_CBCM_Enroll_Date date null,
	Valid_CBCM_Discharge_Date date null,
	Last_Cbcm_Assessment_Date date null,
	Sec_Last_Cbcm_Assessment_Date date null,
	Last_Cbcm_Treatment_Date date null,
	Sec_Last_Cbcm_Treatment_Date date null,
	Last_Cbcm_Locus_Date date null,
	Sec_Last_Cbcm_Locus_Date date null,
	Last_Cbcm_1157Eval_Date date null,
	Sec_Last_Cbcm_1157Eval_Date date null,
	Last_Cbcm_ProgressNote_Date date null,
	Sec_Last_Cbcm_ProgressNote_Date date null,
	HF_Case_Manager varchar(200) null,
	HF_Housing_Specialist varchar(200) null,
	Last_HF_Enroll_date date null,
	Valid_HF_DIscharge_Date date null,
	Last_HF_Intake_Date date null,
	Sec_Last_HF_Intake_Date date null,
	Last_HF_Assessment_Date date null,
	Sec_Last_HF_Assessment_Date date null,
	Last_HF_Treatment_Date date null,
	Sec_Last_HF_Treatment_Date date null,
	Last_HF_Locus_Date date null,
	Sec_Last_HF_Locus_Date date null,
	Last_HF_ProgressNote_Date date null,
	Sec_Last_HF_ProgressNote_Date date null,
	Outreach varchar(200) null,
	Last_Outreach_Enroll_date date null,
	Valid_Outreach_Discharge_Date date null,
	Last_Outreach_Intake_Date date null,
	Sec_Last_Outreach_Intake_Date date null,
	Last_Outreach_Assessment_Date date null,
	Sec_Last_Outreach_Assessment_Date date null,
	Last_Outreach_Treatment_Date date null,
	Sec_Last_Outreach_Treatment_Date date null,
	Last_Outreach_ProgressNote_Date date null,
	Sec_Last_Outreach_ProgressNote_Date date null,
	PSH varchar(200) null,
	Last_PSH_Enroll_Date date null,
	Valid_PSH_Discharge_Date date null,
	Last_PSH_Intake_Date date null,
	Sec_Last_PSH_Intake_Date date null,
	Last_PSH_Assessment_Date date null,
	Sec_Last_PSH_Assessment_Date date null,
	Last_PSH_Treatment_Date date null,
	Sec_Last_PSH_Treatment_Date date null,
	Last_PSH_ProgressNote_Date date null,
	Sec_Last_PSH_ProgressNote_Date date null,
	Last_Housed_date date null,
	Last_housing_location varchar(200) null,
	Last_Housing_Program varchar(200) null,
	Last_Housing_Status varchar(200) null,
	Last_HF_Locus_Level varchar(200) null,
	Last_HF_Locus_Recommendation varchar(200) null,
	Last_HF_Locus_Score varchar(200) null,
	Last_CBCM_Locus_Level varchar(200) null,
	Last_CBCM_Locus_Recommendation varchar(200) null,
	Last_CBCM_Locus_Score varchar(200) null,
	Last_VISPDAT_Submitted date null,
	Last_Path_Enrollment_Date date null,
	Last_Outreach_HMIS_Consent_Signed_Date date null,
	Last_Outreach_HMIS_Assessment_Completed_Date date null,
	Last_KPHC_Consent date null,
	Last_BHA_signed_by_Q date null, 
	Last_ITP_signed_by_Q date null, 
	Last_LOCUS_signed_by_Q date null
);

go


drop proc if exists  cps_hchp.ssis_HCHP_LastClientStatus;

go

create proc cps_hchp.ssis_HCHP_LastClientStatus
as 
begin


	truncate table cps_hchp.HCHP_LastClientStatus;

	
	drop table if exists #cbcm_encounter;
	;with cbcm_enc as (
		select 
			PID, ObsDate, CBCM_Encounter_Type, 
			RowNum = ROW_NUMBER() over(partition by PID, CBCM_Encounter_Type order by obsdate desc)
		from (
			select 
				PID, ObsDate,
				case 
					when CBCM_Encounter_Type like '%Intake%' then 'Intake'
					when CBCM_Encounter_Type like '%Assess%' then 'Assessment'
					when CBCM_Encounter_Type like '%Treat%' then 'Treatment'
					when CBCM_Encounter_Type like '%1157%' then '1157_Eval'
					else CBCM_Encounter_Type
				end CBCM_Encounter_Type
			from cps_hchp.HCHP_Dashboard 
			where CBCM_Encounter_Type is not null
				and CBCM_Encounter_Type not in ('Historical','Enrollment','Discharge')
				--and CBCM_Success = 'successful'
		) x
		--where CBCM_Encounter_Type = 'locus'
	) 
		select 
			PID, 
			pvt.[1157_Eval_1] Last_Cbcm_1157Eval_Date, 
			pvt.[1157_Eval_2] Sec_Last_Cbcm_1157Eval_Date, 
			pvt.Assessment_1 Last_Cbcm_Assessment_Date,
			pvt.Assessment_2 Sec_Last_Cbcm_Assessment_Date,
			pvt.Treatment_1 Last_Cbcm_Treatment_Date, 
			pvt.Treatment_2 Sec_Last_Cbcm_Treatment_Date, 
			pvt.LOCUS_1 Last_Cbcm_Locus_Date,
			pvt.LOCUS_2 Sec_Last_Cbcm_Locus_Date,
			pvt.[Progress note_1] Last_Cbcm_ProgressNote_Date,
			pvt.[Progress note_2] Sec_Last_Cbcm_ProgressNote_Date
		into #cbcm_encounter
		from (
			select PID, ObsDate, CBCM_Encounter_Type + '_' + convert(varchar(30), RowNum) X
			from cbcm_enc
			where RowNum = 1 or RowNum = 2
		) q
		pivot (
			max(obsdate)
			for X in ([1157_Eval_1],[Assessment_1],[LOCUS_1],[Progress note_1],[Treatment_1] ,
						[1157_Eval_2],[Assessment_2],[LOCUS_2],[Progress note_2],[Treatment_2] 
					)
		)pvt

	--	select * from #cbcm_encounter

	
	drop table if exists #hf_encounter;
	;with hf_enc as (
		select 
			PID, ObsDate, HF_Encounter_Type, 
			RowNum = ROW_NUMBER() over(partition by PID, HF_Encounter_Type order by obsdate desc)
		from (
			select 
				PID, ObsDate,
				case 
					when HF_Encounter_Type like '%Intake%' then 'Intake'
					when HF_Encounter_Type like '%Assess%' then 'Assessment'
					when HF_Encounter_Type like '%Treat%' then 'Treatment'
					when HF_Encounter_Type like '%1157%' then '1157_Eval'
					else HF_Encounter_Type
				end HF_Encounter_Type
			from cps_hchp.HCHP_Dashboard 
			where HF_Encounter_Type is not null
				and HF_Encounter_Type not in ('Historical','Enrollment','Discharge')
				--and HF_Success = 'successful'
		) x
	) 
		select 
			PID, 
			pvt.[Intake_1] Last_HF_Intake_Date, 
			pvt.[Intake_2] Sec_Last_HF_Intake_Date, 
			pvt.Assessment_1 Last_HF_Assessment_Date,
			pvt.Assessment_2 Sec_Last_HF_Assessment_Date,
			pvt.Treatment_1 Last_HF_Treatment_Date, 
			pvt.Treatment_2 Sec_Last_HF_Treatment_Date, 
			pvt.LOCUS_1 Last_HF_Locus_Date,
			pvt.LOCUS_2 Sec_Last_HF_Locus_Date,
			pvt.[Progress note_1] Last_HF_ProgressNote_Date,
			pvt.[Progress note_2] Sec_Last_HF_ProgressNote_Date

		into #hf_encounter
		from (
			select PID, ObsDate, HF_Encounter_Type + '_' + convert(varchar(30), RowNum) X
			from hf_enc
			where RowNum = 1 or RowNum = 2
		) q
		pivot (
			max(obsdate)
			for x in ([Intake_1],[Assessment_1],[LOCUS_1],[Progress note_1],[Treatment_1], [Intake_2],[Assessment_2],[LOCUS_2],[Progress note_2],[Treatment_2]  )
		)pvt;

	--	select * from #hf_encounter

	drop table if exists #outreach_encounter;
	;with out_enc as (
		select 
			PID, ObsDate, Outreach_Encounter_Type, 
			RowNum = ROW_NUMBER() over(partition by PID, Outreach_Encounter_Type order by obsdate desc)
		from (
			select 
				PID, ObsDate,
				case 
					when Outreach_Encounter_Type like '%Intake%' then 'Intake'
					when Outreach_Encounter_Type like '%Assess%' then 'Assessment'
					when Outreach_Encounter_Type like '%Treat%' then 'Treatment'
					when Outreach_Encounter_Type like '%1157%' then '1157_Eval'
					else Outreach_Encounter_Type
				end Outreach_Encounter_Type
			from cps_hchp.HCHP_Dashboard 
			where Outreach_Encounter_Type is not null
				and Outreach_Encounter_Type not in ('Historical','Enrollment','Discharge')
				--and Outreach_Success = 'successful'
		) x
	) 
		select 
			PID, 
			pvt.[Intake_1] Last_Outreach_Intake_Date, 
			pvt.[Intake_2] sec_Last_Outreach_Intake_Date, 
			pvt.Assessment_1 Last_Outreach_Assessment_Date,
			pvt.Assessment_2 sec_Last_Outreach_Assessment_Date,
			pvt.Treatment_1 Last_Outreach_Treatment_Date,
			pvt.Treatment_2 sec_Last_Outreach_Treatment_Date,
			pvt.[Progress note_1] Last_Outreach_ProgressNote_Date,
			pvt.[Progress note_2] sec_Last_Outreach_ProgressNote_Date
		into #outreach_encounter
		from (
			select PID, ObsDate, Outreach_Encounter_Type + '_' + convert(varchar(30), RowNum) X
			from out_enc
			where RowNum = 1 or RowNum = 2
		) q
		pivot (
			max(obsdate)
			for x in ([Intake_1],[Assessment_1],[Progress note_1],[Treatment_1],
						[Intake_2],[Assessment_2],[Progress note_2],[Treatment_2]
						)
		)pvt;

	--	select * from #outreach_encounter


	drop table if exists #psh_encounter;
	;with psh_enc as (
		select 
			PID, ObsDate, PSH_Encounter_Type, 
			RowNum = ROW_NUMBER() over(partition by PID, PSH_Encounter_Type order by obsdate desc)
		from (
			select 
				PID, ObsDate,
				case 
					when PSH_Encounter_Type like '%Intake%' then 'Intake'
					when PSH_Encounter_Type like '%Assess%' then 'Assessment'
					when PSH_Encounter_Type like '%Treat%' then 'Treatment'
					when PSH_Encounter_Type like '%1157%' then '1157_Eval'
					else PSH_Encounter_Type
				end PSH_Encounter_Type
			from cps_hchp.HCHP_Dashboard 
			where PSH_Encounter_Type is not null
				and PSH_Encounter_Type not in ('Historical','Enrollment','Discharge')
				--and PSH_Success = 'successful'
		) x
	) 
		select 
			PID, 
			pvt.[Intake_1] Last_PSH_Intake_Date, 
			pvt.[Intake_2] Sec_Last_PSH_Intake_Date, 
			pvt.Assessment_1 Last_PSH_Assessment_Date,
			pvt.Assessment_2 Sec_Last_PSH_Assessment_Date,
			pvt.Treatment_1 Last_PSH_Treatment_Date,
			pvt.Treatment_2 Sec_Last_PSH_Treatment_Date,
			pvt.[Progress note_1] Last_PSH_ProgressNote_Date,
			pvt.[Progress note_2] Sec_Last_PSH_ProgressNote_Date
		into #psh_encounter
		from (
			select PID, ObsDate, PSH_Encounter_Type + '_' + convert(varchar(30), RowNum) X
			from psh_enc
			where RowNum = 1 or RowNum = 2
		) q
		pivot (
			max(obsdate)
			for x in ([Intake_1],[Assessment_1],[Progress note_1],[Treatment_1],
						[Intake_2],[Assessment_2],[Progress note_2],[Treatment_2]
						)
		)pvt;

	--	select * from #psh_encounter


	drop table if exists #hchp_program;
	;with last_enroll_discharge_date as(
		select 
			PID,
			max(CBCM_Enroll_Date) Last_CBCM_Enroll_Date,
			max(CBCM_Discharge_Date) Last_CBCM_Discharge_Date,
			max(HF_Enroll_date) Last_HF_Enroll_date,
			max(HF_DIscharge_Date) Last_HF_DIscharge_Date,
			max(Outreach_Enroll_date) Last_Outreach_Enroll_date,
			max(Outreach_Discharge_Date) Last_Outreach_Discharge_Date,
			max(PSH_Enroll_Date) Last_PSH_Enroll_Date,
			max(PSH_Discharge_Date) Last_PSH_Discharge_Date,
			max(housed_date) Last_Housed_date
		from cps_hchp.HCHP_Dashboard hchp
		group by PID
	), discharge_cleanup as (
		select 
			PID,
			Last_CBCM_Enroll_Date, 
			case when DATEDIFF(day,Last_CBCM_Enroll_Date,Last_CBCM_Discharge_Date) < 0 then null else Last_CBCM_Discharge_Date end Valid_CBCM_Discharge_Date,
			Last_HF_Enroll_date,
			case when DATEDIFF(day,Last_HF_Enroll_date,Last_HF_DIscharge_Date) < 0 then null else Last_HF_DIscharge_Date end Valid_HF_DIscharge_Date,
			Last_Outreach_Enroll_date,
			case when DATEDIFF(day,Last_Outreach_Enroll_date,Last_Outreach_Discharge_Date) < 0 then null else Last_Outreach_Discharge_Date end Valid_Outreach_Discharge_Date,
			Last_PSH_Enroll_Date,
			case when DATEDIFF(day,Last_PSH_Enroll_Date,Last_PSH_Discharge_Date) < 0 then null else Last_PSH_Discharge_Date end Valid_PSH_Discharge_Date,
			Last_Housed_date
		from last_enroll_discharge_date
	), housing_location as(
			select 
				pid, Housing_Location Last_housing_location, RowNum = ROW_NUMBER() over(partition by PID order by obsdate desc)
			from cps_hchp.HCHP_Dashboard
			where Housing_Location is not null
	), Housing_Program as(
			select 
				pid, Housing_Program Last_Housing_Program, RowNum = ROW_NUMBER() over(partition by PID order by obsdate desc)
			from cps_hchp.HCHP_Dashboard
			where Housing_Program is not null
	), Housing_Status as(
			select 
				pid, Housing_Status Last_Housing_Status, RowNum = ROW_NUMBER() over(partition by PID order by obsdate desc)
			from cps_hchp.HCHP_Dashboard
			where Housing_Status is not null
	), bha as (
		select 
			PID, BHA_signed_by_Q, RowNum = ROW_NUMBER() over(partition by PID order by obsdate desc)
		from cps_hchp.HCHP_Dashboard
		where BHA_signed_by_Q is not null
	), itp as (
		select 
			PID, ITP_signed_by_Q, RowNum = ROW_NUMBER() over(partition by PID order by obsdate desc)
		from cps_hchp.HCHP_Dashboard
		where ITP_signed_by_Q is not null
	), locus as (
		select 
			PID, LOCUS_signed_by_Q, RowNum = ROW_NUMBER() over(partition by PID order by obsdate desc)
		from cps_hchp.HCHP_Dashboard
		where LOCUS_signed_by_Q is not null
	)
		select 
			distinct h.pid, 
			Last_Housed_date, loc.Last_housing_location, pro.Last_Housing_Program,stat.Last_Housing_Status,
			pp.CBCM, d.Last_CBCM_Enroll_Date, d.Valid_CBCM_Discharge_Date, 
			pp.HF_Case_Manager, pp.HF_Housing_Specialist, d.Last_HF_Enroll_date, d.Valid_HF_DIscharge_Date, 
			pp.Outreach, d.Last_Outreach_Enroll_date, d.Valid_Outreach_Discharge_Date, 
			pp.PSH, d.Last_PSH_Enroll_Date, d.Valid_PSH_Discharge_Date,
			bha.BHA_signed_by_Q Last_BHA_signed_by_Q,
			itp.ITP_signed_by_Q Last_ITP_signed_by_Q,
			locus.LOCUS_signed_by_Q Last_LOCUS_signed_by_Q
		into #hchp_program
		from cps_hchp.HCHP_Dashboard h
			left join discharge_cleanup d on d.pid = h.PID
			left join cps_all.PatientProfile pp on pp.pid = h.pid
			left join housing_location loc on loc.pid = h.pid and loc.RowNum = 1
			left join Housing_Program pro on pro.pid = h.pid and pro.RowNum = 1
			left join Housing_Status stat on stat.pid = h.pid and stat.RowNum = 1
			left join bha on bha.pid = h.pid and bha.RowNum = 1
			left join itp on itp.pid = h.pid and itp.RowNum = 1
			left join locus on locus.pid = h.pid and locus.RowNum = 1

	--	select * from #hchp_program


	drop table if exists #Last_CBCM_Locus;
	select * 
	into #Last_CBCM_Locus
	from (
		select 
			PID, ObsDate, CBCM_Locus_Level Last_CBCM_Locus_Level, CBCM_Locus_Recommendation Last_CBCM_Locus_Recommendation, CBCM_Locus_Score Last_CBCM_Locus_Score,
			RowNum = ROW_NUMBER() over(partition by pid order by obsdate desc)
		from cps_hchp.HCHP_Dashboard h
		where 
			(h.CBCM_Locus_Level is not null
			or h.CBCM_Locus_Recommendation is not null 
			or h.CBCM_Locus_Score is not null
			)
	) x
	where x.RowNum = 1;

	drop table if exists #Last_HF_Locus;
	select * 
	into #Last_HF_Locus
	from (
		select 
			PID, ObsDate, HF_Locus_Level Last_HF_Locus_Level, HF_Locus_Recommendation Last_HF_Locus_Recommendation, HF_Locus_Score Last_HF_Locus_Score,
			RowNum = ROW_NUMBER() over(partition by pid order by obsdate desc)
		from cps_hchp.HCHP_Dashboard h
		where 
			(h.HF_Locus_Level is not null
			or h.HF_Locus_Recommendation is not null 
			or h.HF_Locus_Score is not null
			)
	) x
	where x.RowNum = 1;		
		
	drop table if exists #Last_vi_spdat_submitted;
	select * 
	into #Last_vi_spdat_submitted
	from (
		select 
			PID, ObsDate, VISPDAT_to_PHOCUSED Last_VISPDAT_Submitted,
			RowNum = ROW_NUMBER() over(partition by pid order by obsdate desc)
		from cps_hchp.HCHP_Dashboard h
		where 
			h.VISPDAT_to_PHOCUSED is not null
			
	) x
	where x.RowNum = 1;		

	drop table if exists #Last_path_enrolled_date;
	select * 
	into #Last_path_enrolled_date
	from (
		select 
			PID, ObsDate, Path_Enrollment Last_Path_Enrollment_Date,
			RowNum = ROW_NUMBER() over(partition by pid order by obsdate desc)
		from cps_hchp.HCHP_Dashboard h
		where 
			h.Path_Enrollment is not null
			
	) x
	where x.RowNum = 1;		

	drop table if exists #last_outreach_hmis_consent;
	select * 
	into #last_outreach_hmis_consent
	from (
		select 
			PID, ObsDate, HMIS_Consent_Outreach Last_HMIS_Consent_SignedOutreach_Date,
			RowNum = ROW_NUMBER() over(partition by pid order by obsdate desc)
		from cps_hchp.HCHP_Dashboard h
		where 
			h.HMIS_Consent_Outreach is not null
			
	) x
	where x.RowNum = 1;		

	drop table if exists #last_outreach_hmis_assessment;
	select * 
	into #last_outreach_hmis_assessment
	from (
		select 
			PID, ObsDate, HMIS_Assessment_Outreach Last_HMIS_Assessment_Outreach_Date,
			RowNum = ROW_NUMBER() over(partition by pid order by obsdate desc)
		from cps_hchp.HCHP_Dashboard h
		where 
			h.HMIS_Assessment_Outreach is not null
			
	) x
	where x.RowNum = 1;	

	drop table if exists #last_KPHC_consent;
	select * 
	into #last_KPHC_consent
	from (
		select 
			PID, ObsDate, KPHC_Consent Last_KPHC_Consent,
			RowNum = ROW_NUMBER() over(partition by pid order by obsdate desc)
		from cps_hchp.HCHP_Dashboard h
		where 
			h.KPHC_Consent is not null
			
	) x
	where x.RowNum = 1;	

		--select * from #cbcm_encounter
		--select * from #hf_encounter
		--select * from #outreach_encounter
		--select * from #psh_encounter
		--select * from #hchp_program
		insert into cps_hchp.HCHP_LastClientStatus (
				d.PID,

				cbcm, Last_CBCM_Enroll_Date, Valid_CBCM_Discharge_Date,

				Last_Cbcm_Assessment_Date, Sec_Last_Cbcm_Assessment_Date, 
				Last_Cbcm_Treatment_Date, Sec_Last_Cbcm_Treatment_Date,
				Last_Cbcm_Locus_Date, Sec_Last_Cbcm_Locus_Date,
				Last_Cbcm_1157Eval_Date,  Sec_Last_Cbcm_1157Eval_Date,
				Last_Cbcm_ProgressNote_Date, Sec_Last_Cbcm_ProgressNote_Date,

				HF_Case_Manager, HF_Housing_Specialist, Last_HF_Enroll_date, Valid_HF_DIscharge_Date, 

				Last_HF_Intake_Date, Sec_Last_HF_Intake_Date,
				Last_HF_Assessment_Date, Sec_Last_HF_Assessment_Date,
				Last_HF_Treatment_Date,  Sec_Last_HF_Treatment_Date,
				Last_HF_Locus_Date, Sec_Last_HF_Locus_Date,
				Last_HF_ProgressNote_Date,Sec_Last_HF_ProgressNote_Date,

				Outreach, Last_Outreach_Enroll_date, Valid_Outreach_Discharge_Date,

				Last_Outreach_Intake_Date, sec_Last_Outreach_Intake_Date,
				Last_Outreach_Assessment_Date,sec_Last_Outreach_Assessment_Date,
				Last_Outreach_Treatment_Date, sec_Last_Outreach_Treatment_Date,
				Last_Outreach_ProgressNote_Date, sec_Last_Outreach_ProgressNote_Date,
				
				PSH, Last_PSH_Enroll_Date, Valid_PSH_Discharge_Date, 
				
				Last_PSH_Intake_Date,Sec_Last_PSH_Intake_Date,
				Last_PSH_Assessment_Date,Sec_Last_PSH_Assessment_Date,  
				Last_PSH_Treatment_Date,Sec_Last_PSH_Treatment_Date,
				Last_PSH_ProgressNote_Date,Sec_Last_PSH_ProgressNote_Date,
				
				Last_Housed_date, Last_housing_location, Last_Housing_Program, Last_Housing_Status,
				Last_HF_Locus_Level, Last_HF_Locus_Recommendation, Last_HF_Locus_Score,
				Last_CBCM_Locus_Level, Last_CBCM_Locus_Recommendation, Last_CBCM_Locus_Score,
				Last_VISPDAT_Submitted, Last_Path_Enrollment_Date, Last_Outreach_HMIS_Consent_Signed_Date, Last_Outreach_HMIS_Assessment_Completed_Date,
				Last_KPHC_Consent,

				Last_BHA_signed_by_Q, Last_ITP_signed_by_Q, Last_LOCUS_signed_by_Q
		)
			select 
				d.PID,

				cbcm, Last_CBCM_Enroll_Date, Valid_CBCM_Discharge_Date,

				Last_Cbcm_Assessment_Date, Sec_Last_Cbcm_Assessment_Date, 
				Last_Cbcm_Treatment_Date, Sec_Last_Cbcm_Treatment_Date,
				Last_Cbcm_Locus_Date, Sec_Last_Cbcm_Locus_Date,
				Last_Cbcm_1157Eval_Date,  Sec_Last_Cbcm_1157Eval_Date,
				Last_Cbcm_ProgressNote_Date, Sec_Last_Cbcm_ProgressNote_Date,

				HF_Case_Manager, HF_Housing_Specialist, Last_HF_Enroll_date, Valid_HF_DIscharge_Date, 

				Last_HF_Intake_Date, Sec_Last_HF_Intake_Date,
				Last_HF_Assessment_Date, Sec_Last_HF_Assessment_Date,
				Last_HF_Treatment_Date,  Sec_Last_HF_Treatment_Date,
				Last_HF_Locus_Date, Sec_Last_HF_Locus_Date,
				Last_HF_ProgressNote_Date,Sec_Last_HF_ProgressNote_Date,

				Outreach, Last_Outreach_Enroll_date, Valid_Outreach_Discharge_Date,

				Last_Outreach_Intake_Date, sec_Last_Outreach_Intake_Date,
				Last_Outreach_Assessment_Date,sec_Last_Outreach_Assessment_Date,
				Last_Outreach_Treatment_Date, sec_Last_Outreach_Treatment_Date,
				Last_Outreach_ProgressNote_Date, sec_Last_Outreach_ProgressNote_Date,
				
				PSH, Last_PSH_Enroll_Date, Valid_PSH_Discharge_Date, 
				
				Last_PSH_Intake_Date,Sec_Last_PSH_Intake_Date,
				Last_PSH_Assessment_Date,Sec_Last_PSH_Assessment_Date,  
				Last_PSH_Treatment_Date,Sec_Last_PSH_Treatment_Date,
				Last_PSH_ProgressNote_Date,Sec_Last_PSH_ProgressNote_Date,
				
				Last_Housed_date, Last_housing_location, Last_Housing_Program, Last_Housing_Status,
				Last_HF_Locus_Level, Last_HF_Locus_Recommendation, Last_HF_Locus_Score,
				Last_CBCM_Locus_Level, Last_CBCM_Locus_Recommendation, Last_CBCM_Locus_Score,
				Last_VISPDAT_Submitted, Last_Path_Enrollment_Date, 
				hm_con.Last_HMIS_Consent_SignedOutreach_Date, hm_ass.Last_HMIS_Assessment_Outreach_Date, kp.Last_KPHC_Consent,

				d.Last_BHA_signed_by_Q, d.Last_ITP_signed_by_Q, d.Last_LOCUS_signed_by_Q
			from #hchp_program d
				left join #cbcm_encounter c on c.pid = d.pid
				left join #hf_encounter h on h.pid = d.PID
				left join #outreach_encounter o on o.pid = d.PID
				left join #psh_encounter p on p.pid = d.PID
				left join #Last_CBCM_Locus cl on cl.PID = d.PID
				left join #Last_HF_Locus hl on hl.PID = d.PID
				left join #Last_vi_spdat_submitted vi on vi.pid = d.pid 
				left join #Last_path_enrolled_date pa on pa.pid = d.PID
				left join #last_outreach_hmis_assessment hm_ass on hm_ass.PID = d.PID
				left join #last_outreach_hmis_consent hm_con on hm_con.PID = d.PID
				left join #last_KPHC_consent kp on kp.PID  = d.PID
	
	
end
go
