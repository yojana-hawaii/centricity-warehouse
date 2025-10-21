
use CpsWarehouse
go
drop table if exists cps_hchp.HCHP_Dashboard;
go
create table cps_hchp.HCHP_Dashboard(
	[SDID] NUMERIC (19)   NOT NULL,
	[XID] numeric(19)	not null,
	[PID] NUMERIC (19)   NOT NULL,
	[PatientID] int not null,
	[ObsDate] date not null,
	[DocSigner] varchar(100) null, 
	[Carf_Program] varchar(2000) null, 
	[Therapist] varchar(2000) null, 
	[Psychiatrist] varchar(2000) null, 
	[External_BH_Provider] varchar(2000) null, 
	[CBCM] varchar(2000) null, 
	[CBCM_Enroll_Date] date null, 
	[CBCM_Discharge_Date] date null, 
	[CBCM_UnableToLocate_Date] date null, 
	[SOAR_Date] date null,
	[SOAR_ID] varchar(20) null,
	[Pysch_Eval_Date] date null,
	[CBCM_Encounter_Type] varchar(2000) null, 
	[CBCM_Method] varchar(2000) null, 
	[CBCM_Success] varchar(2000) null, 
	[CBCM_Duration] varchar(2000) null, 
	[CBCM_LocOfVisit] varchar(2000) null, 
	[11157_Required] varchar(2000) null, 
	[HF_Case_Manager] varchar(2000) null, 
	[HF_Specialist] varchar(2000) null, 
	[HF_Enroll_Date] date null, 
	[HF_DIscharge_Date] date null, 
	[HF_Encounter_Type] varchar(2000) null, 
	[HF_Method] varchar(2000) null, 
	[HF_Success] varchar(2000) null, 
	[HF_Duration] varchar(2000) null, 
	[HF_LocOfVisit] varchar(2000) null, 
	[Outreach] varchar(2000) null, 
	[Outreach_Enroll_Date] date null, 
	[Outreach_Discharge_Date] date null, 
	[Outreach_Encounter_Type] varchar(2000) null, 
	[Outreach_Method] varchar(2000) null, 
	[Outreach_Success] varchar(2000) null, 
	[Outreach_Duration] varchar(2000) null, 
	[Outreach_LocOfVisit] varchar(2000) null, 
	[PSH] varchar(2000) null, 
	[PSH_Enroll_Date] date null, 
	[PSH_Discharge_Date] date null, 
	[PSH_Encounter_Type] varchar(2000) null, 
	[PSH_Method] varchar(2000) null, 
	[PSH_Success] varchar(2000) null, 
	[PSH_Duration] varchar(2000) null, 
	[PSH_LocOfVisit] varchar(2000) null, 
	[Housing_Status] varchar(2000) null, 
	[Housing_Program] varchar(2000) null, 
	[Housing_Location] varchar(2000) null,
	[Housed_Date] date null,
	[BPRS] varchar(2000) null, 
	[PHQ9] varchar(2000) null, 
	[Comment] varchar(2000) null, 
	[HF_Locus_Score] smallint null, 
	[HF_Locus_Level] varchar(2000) null, 
	[HF_Locus_Recommendation] varchar(2000) null, 
	[CBCM_Locus_Score] smallint null, 
	[CBCM_Locus_Level] varchar(2000) null, 
	[CBCM_Locus_Recommendation] varchar(2000) null, 
	[HMIS_Consent_CBCM] date null, 
	[HMIS_Consent_HF] date null, 
	[HMIS_Consent_Outreach] date null, 
	[HMIS_Consent_PSH] date null, 
	[HMIS_Assessment_CBCM] date null, 
	[HMIS_Assessment_HF] date null, 
	[HMIS_Assessment_Outreach] date null, 
	[HMIS_Assessment_PSH] date null, 
	[BHA_signed_by_Q] date null, 
	[LOCUS_signed_by_Q] date null, 
	[ITP_signed_by_Q] date null, 
	[VISPDAT_with_client] date null, 
	[VISPDAT_to_PHOCUSED] date null, 
	[Path_Enrollment] date null, 
	[MoveIn_Date] date null, 
	[MoveOut_Date] date null, 
	[Cps_Consent] date null, 
	[CBCM_DSP_Data] smallint null, 
	[HF_DSP_Data]  smallint null, 
	[Outreach_DSP_Data] smallint null, 
	[PSH_DSP_Data] smallint null, 
	[CBCM_DSP_Assess] smallint null, 
	[HF_DSP_Assess] smallint null, 
	[Outreach_DSP_Assess] smallint null, 
	[PSH_DSP_Assess] smallint null, 
	[CBCM_DSP_Plan] smallint null, 
	[HF_DSP_Plan] smallint null, 
	[Outreach_DSP_Plan] smallint null, 
	[PSH_DSP_Plan] smallint null, 
	[Suicide_Thoughts] varchar(2000) null, 
	[Homicide_Thoughts] varchar(2000) null, 
	[Carf_Pregnant] varchar(2000) null, 
	[Carf_Prenatal_care] varchar(2000) null, 
	[Carf_Prenatal_Substance_Abuse] varchar(2000) null


	PRIMARY KEY CLUSTERED ([SDID], [ObsDate]),

)	
go

drop proc if exists cps_hchp.ssis_HCHP_Dashboard;
go

create proc cps_hchp.ssis_HCHP_Dashboard
as
begin
	truncate table cps_hchp.HCHP_Dashboard;
	
	declare @StartDate date = '2000-01-01';
	declare @FlowsheetId numeric(19,0) = 1964271251314260; /*ZZcarf Dashboard flowsheet*/
	--function to create dynamic pivot sql
	declare @pivoted_sql nvarchar(max) = fxn.ConvertFlowsheetIntoDynamicPivot( @FlowsheetId, @StartDate)
	--print @pivoted_sql
	exec sp_executesql @pivoted_sql

	drop table if exists #pivot_table;
	select * 
	into #pivot_table
	from  ##dynamic_temp_table

	drop table if exists ##dynamic_temp_table;

	--	select * from #pivot_table where pid = 1499091113300010 order by obsdate
	update #pivot_table
	set [HF_Encounter_Type] = 'before_go_live'
	--select * from #pivot_table
	where hf_enroll_date is not null and [HF_Encounter_Type] is null

	update #pivot_table
	set [CBCM_Encounter_Type] = 'before_go_live'
	--select * from #pivot_table
	where cbcm_enroll_date is not null and [CBCM_Encounter_Type] is null

	update #pivot_table
	set [Outreach_Encounter_Type] = 'before_go_live'
	--select * from #pivot_table
	where Outreach_enroll_date is not null and [Outreach_Encounter_Type] is null

	update #pivot_table
	set [PSH_Encounter_Type] = 'before_go_live'
	--select * from #pivot_table
	where PSH_enroll_date is not null and [PSH_Encounter_Type] is null


	/* Find invalid Dates format - last 3 says cannot find
	select * 
	from #pivot_table
	where 
		([CBCM_Enroll_Date] is not null and isdate([CBCM_Enroll_Date]) = 0)
		or ([CBCM_Discharge_Date] is not null and isdate([CBCM_Discharge_Date]) = 0)
		or ([HF_Enroll_Date] is not null and isdate([HF_Enroll_Date]) = 0)
		or ([HF_DIscharge_Date] is not null and isdate([HF_DIscharge_Date]) = 0)
		or ([Outreach_Enroll_Date] is not null and isdate([Outreach_Enroll_Date]) = 0)
		or ([Outreach_Discharge_Date] is not null and isdate([Outreach_Discharge_Date]) = 0)
		or ([PSH_Enroll_Date] is not null and isdate([PSH_Enroll_Date]) = 0)
		or ([PSH_Discharge_Date] is not null and isdate([PSH_Discharge_Date]) = 0)

		or ([Housed_Date] is not null and isdate([Housed_Date]) = 0)

		or ([HMIS_Consent_CBCM] is not null and isdate([HMIS_Consent_CBCM]) = 0)
		or ([HMIS_Consent_HF] is not null and isdate([HMIS_Consent_HF]) = 0)
		or ([HMIS_Consent_Outreach] is not null and isdate([HMIS_Consent_Outreach]) = 0)
		or ([HMIS_Consent_PSH] is not null and isdate([HMIS_Consent_PSH]) = 0)
		or ([HMIS_Assessment_CBCM] is not null and isdate([HMIS_Assessment_CBCM]) = 0)
		or ([HMIS_Assessment_HF] is not null and isdate([HMIS_Assessment_HF]) = 0)
		or ([HMIS_Assessment_Outreach] is not null and isdate([HMIS_Assessment_Outreach]) = 0)
		or ([HMIS_Assessment_PSH] is not null and isdate([HMIS_Assessment_PSH]) = 0)

		or ([BHA_signed_by_Q] is not null and isdate([BHA_signed_by_Q]) = 0)
		or ([LOCUS_signed_by_Q] is not null and isdate([LOCUS_signed_by_Q]) = 0)
		or ([ITP_signed_by_Q] is not null and isdate([ITP_signed_by_Q]) = 0)

		or ([VISPDAT_with_client] is not null and isdate([VISPDAT_with_client]) = 0)
		or ([VISPDAT_to_PHOCUSED] is not null and isdate([VISPDAT_to_PHOCUSED]) = 0)

		or ([Path_Enrollment] is not null and isdate([Path_Enrollment]) = 0)
		or ([MoveIn_Date] is not null and isdate([MoveIn_Date]) = 0)
		or ([MoveOut_Date] is not null and isdate([MoveOut_Date]) = 0)
		or ([Cps_Consent] is not null and isdate([Cps_Consent]) = 0)

		or ([CBCM_UnableToLocate_Date] is not null and isdate([CBCM_UnableToLocate_Date]) = 0)
		or ([SOAR_Date] is not null and isdate([SOAR_Date]) = 0)
		or ([Pysch_Eval_Date] is not null and isdate([Pysch_Eval_Date]) = 0)


	*/	

	

	;with u as (
		select  pvt.* 
		from #pivot_table pvt
			--inner join cps_all.PatientProfile pp on pp.pid = pvt.pid	 and pp.TestPatient = 0
		where [CBCM_Encounter_Type] is not null 
			or [HF_Encounter_Type] is not null 
			or [Outreach_Encounter_Type] is not null 
			or [PSH_Encounter_Type] is not null 
	)
	insert into cps_hchp.HCHP_Dashboard(
		PID, SDID, XID, PatientID,[ObsDate],
		[Carf_Program], [Therapist], [Psychiatrist], [External_BH_Provider], 
		[CBCM], [CBCM_Enroll_Date], [CBCM_Discharge_Date], [CBCM_Encounter_Type], 
		[CBCM_Method], [CBCM_Success], [CBCM_Duration], [CBCM_LocOfVisit], [11157_Required], 
		[HF_Case_Manager], [HF_Specialist], [HF_Enroll_Date], [HF_DIscharge_Date], [HF_Encounter_Type], 
		[HF_Method], [HF_Success], [HF_Duration], [HF_LocOfVisit], 
		[Outreach], [Outreach_Enroll_Date], [Outreach_Discharge_Date], [Outreach_Encounter_Type], 
		[Outreach_Method], [Outreach_Success], [Outreach_Duration], [Outreach_LocOfVisit], 
		[PSH], [PSH_Enroll_Date], [PSH_Discharge_Date], [PSH_Encounter_Type], [PSH_Method], 
		[PSH_Success], [PSH_Duration], [PSH_LocOfVisit], 
		[Housing_Status], [Housing_Program], [Housing_Location], [Housed_Date],
		[BPRS], [PHQ9], [Comment], 
		[HF_Locus_Score], [HF_Locus_Level], [HF_Locus_Recommendation], 
		[CBCM_Locus_Score], [CBCM_Locus_Level], [CBCM_Locus_Recommendation], 
		[HMIS_Consent_CBCM], [HMIS_Consent_HF], [HMIS_Consent_Outreach], [HMIS_Consent_PSH], 
		[HMIS_Assessment_CBCM], [HMIS_Assessment_HF], [HMIS_Assessment_Outreach], [HMIS_Assessment_PSH], 
		[BHA_signed_by_Q], [LOCUS_signed_by_Q], [ITP_signed_by_Q], 
		[VISPDAT_with_client], [VISPDAT_to_PHOCUSED], [Path_Enrollment], 
		[MoveIn_Date], [MoveOut_Date], [Cps_Consent], 
		[CBCM_DSP_Data], [HF_DSP_Data], [Outreach_DSP_Data], [PSH_DSP_Data], 
		[CBCM_DSP_Assess], [HF_DSP_Assess], [Outreach_DSP_Assess], [PSH_DSP_Assess], 
		[CBCM_DSP_Plan], [HF_DSP_Plan], [Outreach_DSP_Plan], [PSH_DSP_Plan], 
		[Suicide_Thoughts], [Homicide_Thoughts], [Carf_Pregnant], [Carf_Prenatal_care], [Carf_Prenatal_Substance_Abuse],
		[DocSigner],
		[CBCM_UnableToLocate_Date],[SOAR_Date],[SOAR_ID],[Pysch_Eval_Date]
	)
	select
		PID, SDID, XID, PatientID,[ObsDate],
		[Carf_Program], [Therapist], [Psychiatrist], [External_BH_Provider], 
		[CBCM], [CBCM_Enroll_Date], [CBCM_Discharge_Date], [CBCM_Encounter_Type], 
		[CBCM_Method], [CBCM_Success], [CBCM_Duration], [CBCM_LocOfVisit], [11157_Required], 
		[HF_Case_Manager], [HF_Specialist], [HF_Enroll_Date], [HF_DIscharge_Date], [HF_Encounter_Type], 
		[HF_Method], [HF_Success], [HF_Duration], [HF_LocOfVisit], 
		[Outreach], [Outreach_Enroll_Date], [Outreach_Discharge_Date], [Outreach_Encounter_Type], 
		[Outreach_Method], [Outreach_Success], [Outreach_Duration], [Outreach_LocOfVisit], 
		[PSH], [PSH_Enroll_Date], [PSH_Discharge_Date], [PSH_Encounter_Type], [PSH _Method], 
		[PSH_Success], [PSH_Duration], [PSH_LocOfVisit], 
		[Housing_Status], [Housing_Program], [Housing_Location], [Housed_Date],
		[BPRS], [PHQ9], [Comment], 
		[HF_Locus_Score], [HF_Locus_Level], [HF_Locus_Recommendation], 
		[CBCM_Locus_Score], [CBCM_Locus_Level], [CBCM_Locus_Recommendation], 
		[HMIS_Consent_CBCM], [HMIS_Consent_HF], [HMIS_Consent_Outreach], [HMIS_Consent_PSH], 
		[HMIS_Assessment_CBCM], [HMIS_Assessment_HF], [HMIS_Assessment_Outreach], [HMIS_Assessment_PSH], 
		[BHA_signed_by_Q], 
		case when isdate([LOCUS_signed_by_Q]) = 1 then [LOCUS_signed_by_Q] end, 
		[ITP_signed_by_Q], 
		[VISPDAT_with_client], [VISPDAT_to_PHOCUSED], [Path_Enrollment], 
		[MoveIn_Date], [MoveOut_Date], [Cps_Consent],  
		
		case when [CBCM_DSP_Data] is not null then 1 else 0 end [CBCM_DSP_Data], 
		case when [HF_DSP_Data] is not null then 1 else 0 end [HF_DSP_Data], 
		case when [Outreach_DSP_Data] is not null then 1 else 0 end [Outreach_DSP_Data], 
		case when [PSH_DSP_Data] is not null then 1 else 0 end [PSH_DSP_Data], 

		case when [CBCM_DSP_Assess] is not null then 1 else 0 end [CBCM_DSP_Assess], 
		case when [HF_DSP_Assess] is not null then 1 else 0 end [HF_DSP_Assess], 
		case when [Outreach_DSP_Assess] is not null then 1 else 0 end [Outreach_DSP_Assess], 
		case when [PSH_DSP_Assess] is not null then 1 else 0 end [PSH_DSP_Assess], 
		

		case when [CBCM_DSP_Plan] is not null then 1 else 0 end [CBCM_DSP_Plan], 
		case when [HF_DSP_Plan] is not null then 1 else 0 end [HF_DSP_Plan], 
		case when [Outreach_DSP_Plan] is not null then 1 else 0 end [Outreach_DSP_Plan], 
		case when [PSH_DSP_Plan] is not null then 1 else 0 end [PSH_DSP_Plan], 

		[Suicide_Thoughts], [Homicide_Thoughts], [Carf_Pregnant], [Carf_Prenatal_care], [Carf_Prenatal_Substance_Abuse],
		ListName,
		--[CBCM_UnableToLocate_Date],[SOAR_Date],[SOAR_ID],[Pysch_Eval_Date]
		[CBCM_Unable_to_Locate],[SOAR Date], [SOAR ID], [Psych Eval Date]
	from u

	--skipped locus signed by Q becuase it was not a valid date -> email angela until HCHP fixes it
	select patientid PatientID, obsdate ObsDate, [LOCUS_signed_by_Q] [LOCUS_signed_by_Q] 
	into #invalidDate
	from #pivot_table
	where isdate([LOCUS_signed_by_Q]) != 1 and [LOCUS_signed_by_Q] is not null

	declare @invalidDate varchar(max);
	select @invalidDate = count(*)
	from #invalidDate

	if @invalidDate > 0
	begin
		declare @email_body varchar(max) = 'Hello,
		</br></br>
This is an auto-generated email. Below is the list of patients with invalid date format. Need to edit in flowsheet.
		
';

		declare @xml varchar(max);

		set @xml = cast
			(
				(
					select 
						PatientID as 'td','', ObsDate as 'td','', LOCUS_signed_by_Q as 'td','' 
					from #invalidDate
					for xml path('tr'), elements
				) as nvarchar(max)
			);
		
		
		set @email_body = @email_body + '
				<html><body>
				<H3>Duplicates for today.</H3>
				<table border = 1>
				<tr>
					<th> Patient ID </th>
					<th> Date </th>
					<th> Locus Signed By Q </th>
				</tr>
			'

		set @email_body = @email_body + @xml + '</table></body></html>' + '
		</br></br>

Thank you </br>
me
	'
	--print @email_body

			--exec msdb.dbo.sp_send_dbmail
			--	@profile_name = 'profile-sql',
			--	@recipients = 'a@b.c',
			--	@copy_recipients = 'd@e.f',
			--	@body_format = 'HTML',
			--	@body = @email_body,
			--	@subject = 'Auto-generated email: Invalid Date format'; 
	end
end

go
