
use CpsWarehouse
go

drop table if exists cps_obs.Aapcho;
go
create table cps_obs.Aapcho (
	PID numeric(19,0) not null,
	SDID numeric(19,0) not null,
	LastPCPApptDate date null,
	LastPCPApptNotSure varchar(6) null,
	ScheduleApptWithPCP varchar(3) null,
	CovidVaccineReceived varchar(8) null,
	VaccinePlan varchar(6) null,
	VaccineHesitancy varchar(3) null,
	DistrustHealthcare varchar(3) null,
	DistrustGovernment varchar(3) null,
	CulturalReasons varchar(3) null,
	LowCovidLiteracy varchar(3) null,
	MisinformationSocialMedia varchar(3) null,
	MisinformationFamilyFriends varchar(3) null,
	MisinformationOther varchar(100) null,
	OtherChronicIlness varchar(3) null,
	Allergies varchar(3) null,
	HadCovid varchar(3) null,
	RefuseToAnswer varchar(3) null,
	NoTime varchar(3) null,
	Work varchar(3) null,
	School varchar(3) null,
	Technology varchar(3) null,
	ConvenientTime varchar(3) null,
	Transport varchar(3) null,
	Child_Elder_Care varchar(3) null,
	NoSiteNearMe varchar(3) null,
	OtherBarrier varchar(100) null,
	ProvidedCovidEducation varchar(3) null,
	TransportationArranged varchar(3) null,
	VaccineLocationInformation varchar(3) null,
	VaccineDate date null,
	VaccineTime varchar(10) null,
	VaccineLocation varchar(20) null,
	ApptPCP date null,
	ApptBH date null,
	ApptEligibility date null,
	ApptOutreach date null,
	NoAction varchar(3) null,
	OtherBarrierReduction varchar(100) null,
	FollowupVaccineAppt varchar(3) null,
	FollowupPCPAppt varchar(3) null,
	FollowupBHAppt varchar(3) null,
	FollowupEligibilityAppt varchar(3) null,
	OtherFollowup varchar(100) null
)
go

drop proc if exists cps_obs.ssis_Aapcho;
go
create proc cps_obs.ssis_Aapcho
as
begin
	
	truncate table cps_obs.Aapcho;

	declare @hdid varchar(max) = '';
	declare @startdate date = '2021-07-20', @enddate date = convert(date, getdate() );

	-- comma separate the HDID
	select @hdid = @hdid + coalesce(', ' + convert(varchar(10), hdid), '')
	from cps_obs.ObsHead
	where ObsTerm like 'wnd%Type'
		and obsterm not in ('WND23TYPE','WND24TYPE','WND25TYPE')

	--print @hdid	
	-- remove leading comma and space
	set @hdid = SUBSTRING(@hdid, 3, len(@hdid) )

	--print @hdid

	--build dynamic pivot for selected HDID
	declare @pivoted_sql nvarchar(max) = fxn.ConvertObsHdidIntoDynamicPivot( @hdid, @StartDate, @EndDate)

	--execute dynamically created dynamic sql
	exec sp_executesql @pivoted_sql


	--transfer global temp table to local temp table
	drop table if exists #pivot_table;
	select * 
	into #pivot_table
	from  ##dynamic_temp_table


	--drop global temp tabe
	drop table if exists ##dynamic_temp_table;

	; with u as (
		select 
			p.PID PID, p.SDID SDID, 
			convert(date,p.wnd1type) LastPCPApptDate, p.wnd2type LastPCPApptNotSure, p.wnd3type ScheduleApptWithPCP,
			p.wnd4type CovidVaccineReceived, p.wnd5type VaccinePlan,
			case when p.wnd6type <> '' then 'yes'  end VaccineHesitancy,
			case when p.wnd7type <> '' then 'yes' end DistrustHealthcare,
			case when p.wnd8type <> '' then 'yes' end DistrustGovernment,
			case when p.wnd9type <> '' then 'yes' end CulturalReasons,
			case when p.wnd10type <> '' then 'yes' end LowCovidLiteracy,
		
			case when p.wnd11type like 'social media%' then 'yes'  end MisinformationSocialMedia,
			case when p.wnd11type like '%family/friends/relatives%' then 'yes' end MisinformationFamilyFriends,
			case 
				when charindex('Other,',wnd11type) > 0 
					then convert(varchar(100),ltrim(rtrim(substring(wnd11type, charindex('Other,',wnd11type) + 6, len(wnd11type) - charindex('Other,',wnd11type) - 5 ))))
				when charindex('Other',wnd11type) > 0 then 'Other'
			end MisinformationOther,

			case when p.wnd12type like 'Other Chronic Illness%' then 'yes'  end OtherChronicIlness,
			case when p.wnd12type like '%Allergies%' then 'yes'  end Allergies,
			case when p.wnd12type like '%had covid-19%' then 'yes'  end HadCovid,
			case when p.wnd13type <> '' then 'yes'  end RefuseToAnswer,

			case when p.wnd14type like '%No Time%' then 'yes'  end NoTime,
			case when p.wnd14type like '%Work%' then 'yes'  end Work,
			case when p.wnd14type like '%School%' then 'yes'  end School,
			case when p.wnd14type like '%Unable to use/access technology to make appointment%' then 'yes'  end Technology,
			case when p.wnd14type like '%no convenient time(s) available%' then 'yes'  end ConvenientTime,
			case when p.wnd14type like '%No transportation%' then 'yes'  end Transport,
			case when p.wnd14type like '%No child/ elder care%' then 'yes'  end Child_Elder_Care,
			case when p.wnd14type like '%no site near me%' then 'yes'  end NoSiteNearMe,
			case 
				when charindex('Other,',wnd14type) > 0 
					then convert(varchar(100),ltrim(rtrim(substring(wnd14type, charindex('Other,',wnd14type) + 6, len(wnd14type) - charindex('Other,',wnd14type) - 5 ))))
				when charindex('Other',wnd14type) > 0 then 'Other'
			end OtherBarrier,

			case when p.wnd15type <> '' then 'yes' end ProvidedCovidEducation,
			case when p.wnd16type <> '' then 'yes' end TransportationArranged,
			case when p.wnd17type <> '' then 'yes' end VaccineLocationInformation,

			case 
				when charindex('Date:',wnd18type) > 0 
					then 
						case when ltrim(rtrim(substring(wnd18type, charindex('Date:',wnd18type) + 5, charindex('; Time',wnd18type) -6 ))) = 'n/a' then null
							else convert(date, ltrim(rtrim(substring(wnd18type, charindex('Date:',wnd18type) + 5, charindex('; Time',wnd18type) -6 ))))
						end
			end VaccineDate,
			case 
				when charindex('Time:',wnd18type) > 0 
					then 
						case when ltrim(rtrim(substring(wnd18type, charindex('Time:',wnd18type) + 5, charindex('; Location:',wnd18type) - charindex('Time:',wnd18type) - 5 ))) = 'n/a' then null
							else convert(varchar(10), ltrim(rtrim(substring(wnd18type, charindex('Time:',wnd18type) + 5, charindex('; Location:',wnd18type) - charindex('Time:',wnd18type) - 5 ))))
						end
			end VaccineTime,
			case 
				when charindex('Location:',wnd18type) > 0 
					then 
						case when ltrim(rtrim(substring(wnd18type, charindex('Location:',wnd18type) + 10, len(wnd18type) - charindex('; Location:',wnd18type) - 10))) in ('n/a','') then null
							else convert(varchar(20), ltrim(rtrim(substring(wnd18type, charindex('Location:',wnd18type) + 10, len(wnd18type) - charindex('; Location:',wnd18type) - 10))))
						end
			end VaccineLocation,

			p.wnd19type  ,
			case 
				when charindex('PCP:',wnd19type) > 0 
					then 
						case when ltrim(rtrim(substring(wnd19type, charindex('PCP:',wnd19type) + 4, charindex('; BH:',wnd19type) - 5))) = 'n/a' then null
							else convert(date, ltrim(rtrim(substring(wnd19type, charindex('PCP:',wnd19type) + 4, charindex('; BH:',wnd19type) -5))))
						end
			end ApptPCP,
			case 
				when charindex('BH:',wnd19type) > 0 
					then 
						case when ltrim(rtrim(substring(wnd19type, charindex('BH:',wnd19type) + 3, charindex('; Eligibility:',wnd19type) - charindex('BH:',wnd19type) - 3 ))) in ('n/a','') then null
							else convert(date, ltrim(rtrim(substring(wnd19type, charindex('BH:',wnd19type) + 3, charindex('; Eligibility:',wnd19type) - charindex('BH:',wnd19type) - 3 ))))
						end
			end ApptBH,

			case 
				when charindex('Eligibility:',wnd19type) > 0 
					then 
						case when ltrim(rtrim(substring(wnd19type, charindex('Eligibility:',wnd19type) + 12, charindex('; Outreach:',wnd19type) - charindex('Eligibility:',wnd19type) - 12 ))) in ('n/a','') then null
							else convert(date, ltrim(rtrim(substring(wnd19type, charindex('Eligibility:',wnd19type) + 12, charindex('; Outreach:',wnd19type) - charindex('Eligibility:',wnd19type) - 12 ))))
						end
			end ApptEligibility,

			case 
				when charindex('Eligibility:',wnd19type) > 0 
					then 
						case when ltrim(rtrim(substring(wnd19type, charindex('Outreach:',wnd19type) + 9, len(wnd19type) - charindex('; Outreach:',wnd19type) - 10))) in ('n/a','') then null
							else convert(date, ltrim(rtrim(substring(wnd19type, charindex('Outreach:',wnd19type) + 9, len(wnd19type) - charindex('; Outreach:',wnd19type) - 10))))
						end
			end ApptOutreach,

			case when p.wnd20type <> '' then 'yes' end NoAction,

			case 
				when charindex('Other,',wnd21type) > 0 
					then convert(varchar(100), ltrim(rtrim(substring(wnd21type, charindex('Other,',wnd21type) + 6, len(wnd21type) - charindex('Other,',wnd21type) - 5 ))))
				when charindex('Other',wnd21type) > 0 then 'Other'
			end OtherBarrierReduction,

			case when p.wnd22type like '%Vaccination Appt%' then 'yes' end FollowupVaccineAppt,
			case when p.wnd22type like '%PCP%' then 'yes' end FollowupPCPAppt,
			case when p.wnd22type like '%BH%' then 'yes' end FollowupBHAppt,
			case when p.wnd22type like '%Eligibility%' then 'yes' end FollowupEligibilityAppt,
			case 
				when charindex('Other,',wnd22type) > 0 
					then convert(varchar(100), ltrim(rtrim(substring(wnd22type, charindex('Other,',wnd22type) + 6, len(wnd22type) - charindex('Other,',wnd22type) - 5 ))))
				when charindex('Other',wnd22type) > 0 then 'Other'
			end OtherFollowup
		--into #test
		from #pivot_table p
	)
	insert into cps_obs.Aapcho(
		PID,SDID,LastPCPApptDate,LastPCPApptNotSure,ScheduleApptWithPCP,CovidVaccineReceived,VaccinePlan,
		VaccineHesitancy,DistrustHealthcare,DistrustGovernment,CulturalReasons,LowCovidLiteracy,
		MisinformationSocialMedia,MisinformationFamilyFriends,MisinformationOther,
		OtherChronicIlness,Allergies,HadCovid,
		RefuseToAnswer,
		NoTime,Work,School,Technology,ConvenientTime,Transport,Child_Elder_Care,NoSiteNearMe,OtherBarrier,
		ProvidedCovidEducation,TransportationArranged,VaccineLocationInformation,
		VaccineDate,VaccineTime,VaccineLocation,
		ApptPCP,ApptBH, ApptEligibility,ApptOutreach,NoAction,OtherBarrierReduction,
		FollowupVaccineAppt,FollowupPCPAppt,FollowupBHAppt,FollowupEligibilityAppt,OtherFollowup
	)
	select
		PID,SDID,LastPCPApptDate,LastPCPApptNotSure,ScheduleApptWithPCP,CovidVaccineReceived,VaccinePlan,
		VaccineHesitancy,DistrustHealthcare,DistrustGovernment,CulturalReasons,LowCovidLiteracy,
		MisinformationSocialMedia,MisinformationFamilyFriends,MisinformationOther,
		OtherChronicIlness,Allergies,HadCovid,
		RefuseToAnswer,
		NoTime,Work,School,Technology,ConvenientTime,Transport,Child_Elder_Care,NoSiteNearMe,OtherBarrier,
		ProvidedCovidEducation,TransportationArranged,VaccineLocationInformation,
		VaccineDate,VaccineTime,VaccineLocation,
		ApptPCP,ApptBH, ApptEligibility,ApptOutreach,NoAction,OtherBarrierReduction,
		FollowupVaccineAppt,FollowupPCPAppt,FollowupBHAppt,FollowupEligibilityAppt,OtherFollowup
	from u
end
go
