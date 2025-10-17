
use CpsWarehouse
go

drop table if exists [cps_all].[PatientProfile];
go
CREATE TABLE [cps_all].[PatientProfile] (
	[TestPatient]		smallint	not null,
    [PatientActive]    smallint    not NULL,
    [PID]              NUMERIC (19)    NOT NULL,
    [PatientProfileID] INT             NOT NULL,
    [PatientID]        varchar (20)    NOT NULL,
    [SensitiveChart]   SMALLINT        NOT NULL,
	[PatientAPI]		smallint		not null,
    [Name]             varchar (100)  NOT NULL,
    [Last]             varchar (60)   NULL,
    [First]            varchar (35)   NULL,
    [DoB]              DATE            NULL,

    [AgeDecimal]       AS              cast(DATEDIFF(day, [DoB], getdate()) / 365.25 as decimal(10,2) ),
    [AgeRounded]       AS              CONVERT([int],round(DATEDIFF(day, [DoB], getdate()) / 365.25 ,(0))),

    [Sex]              varchar (1)    NULL,
    [SexualOrientation]           varchar (50)   NULL,
    [GenderPreference]           varchar (50)   NULL,
    [Zip]              varchar (10)   NULL,
    [Phone1]           varchar (50)   NULL,
    [Phone2]           varchar (50)   NULL,
    [Phone3]           varchar (50)   NULL,
    [Email]            varchar (255)  NULL,
    [MaritalStatus]    varchar (200)  NULL,
    [Facility]		   varchar(50)    NULL,

	[LocAbbrevName]	varchar(50)		null,
    [PCP]			   varchar(50)    NULL,
	PCP_PVID			numeric(19,0) null,
    [ResponsibleProvider]			   varchar(50)    NULL,
	ResponsibleProvider_PVID			numeric(19,0) null,


    [Old_CaseManager]      varchar (4000) NULL,
    [CBCM]      varchar (4000) NULL,
    [HF_Case_Manager]      varchar (4000) NULL,
    [HF_Housing_Specialist]      varchar (4000) NULL,
    [Outreach]      varchar (4000) NULL,
    [PSH]      varchar (4000) NULL,
    [Therapist]        varchar (4000) NULL,
    [Psych]            varchar (4000) NULL,
    [ExternalProvider] varchar (4000) NULL,

    [Veteran]          tinyint             NULL,
    [Employment]       varchar (200)   NULL,
    [Education]        varchar (26)    NULL,
    [Language]         varchar (60)    NULL,

    [Citizenship]      varchar (200)   NULL,
    [BirthPlace]       varchar (160)   NULL,
    [DateOfEntry]      DATE            NULL,
    [FamilySize]       TINYINT         NULL,
    [AnnualIncome]    INT             NULL,
    [NotSlideFeeQualified]    TINYINT             NULL,
    [SlidingFeeCurrent]    TINYINT             NULL,

	LimitedEnglish			tinyint null,
	IsHomeless				tinyint null,
	IsPublicHousing			tinyint null,
	AgriculturalMigration	varchar(50) null,

    CONSTRAINT [PK_dimPatientProfile_PID] PRIMARY KEY CLUSTERED ([PID] ASC),
);

go

drop procedure if exists [cps_all].[ssis_PatientProfile];
go
CREATE procedure [cps_all].[ssis_PatientProfile]
as
begin

truncate table cps_all.patientProfile;

with u AS (
	SELECT 
		pp.PID PID, pp.patientprofileid PatientProfileid,pp.PatientId PatientId, 
		isnull(pp.SensitiveChart,0) SensitiveChart,
		pp.hasPatientAccess [PatientAPI],
		isnull(pp.[last],'') + ', ' + isnull(pp.first,'') AS 'Name', 
		pp.[last] [Last],	
		pp.first [First],
		CONVERT(date,pp.Birthdate) AS 'DOB',
		
		pp.Sex Sex, 
		so.Description SexualOrientation,
		gi.Description GenderPreference,

		pp.Zip Zip, 
		case when pp.phone1type = 'No Phone' then null else pp.phone1 + ' (' + pp.phone1type + ')' end Phone1,
		case when pp.phone2type = 'No Phone' then null else pp.phone2 + ' (' + pp.phone2type + ')' end Phone2,
		case when pp.phone3type = 'No Phone' then null else pp.phone3 + ' (' + pp.phone3type + ')' end Phone3,
		marriage.Description AS 'MaritalStatus',

		case 
			when pp.emailAddress in ('mone', 'none','','.') then null 
			when pp.emailAddress not like '%@%' then null
			else pp.EmailAddress 
		end emailAddress,

		loc.LocAbbrevName, 
		loc.Facility,
		pcp.ListName AS PCP,
		pcp.PVID PCP_PVID,
		res.ListName AS [ResponsibleProvider],
		res.PVID ResponsibleProvider_PVID,
		casemngr.name Old_CaseManager,
		outreach.name Outreach,
		hf_cm.Name HF_Case_Magager,
		hf_sp.Name HF_Housing_Specialist,
		cbcm.Name CBCM,
		psh.Name PSH,
		ther.NAME Therapist,
		psych.name Psych,
		outside.name Externalprovider,
		t1.Education AS Education,
		t2.BirthPlace BirthPlace,
		CONVERT(Date,t2.[DateOf Entry]) DateOfEntry,
		--t2.[DateOf Entry],
		case when vet.Description = 'Veteran' then 1 when vet.Description = 'Non-Veteran' then 0 end  [Veteran],
		emp.Description AS 'Employment',
		
		l.ShortDescription AS 'Language',  
		cit.Description AS Citizenship,
		
		case 
			when inc.FamilySize <= 0 then null 
			when inc.FamilySize > 15 then null
		else inc.familySize end FamilySize, 
		
		cast(case when inc.HasIncome = 0 then null 
			when inc.AnnualIncome = 0.0000 then null 
			when inc.AnnualIncome < 100 then null
			else inc.AnnualIncome
		end as int) AnnualIncome,

		inc.NotSlideFeeQualified [NotSlideFeeQualified],
		inc.isCurrent SlidingFeeCurrent,

		chc.IsLimitedEnglishProficient as LimitedEnglish,
	
		hou.IsHomeless IsHomeless,
		hou.IsPublicHousing IsPublicHousing,
		ag.Description AgriculturalMigration,

		case when pp.pstatus in ('I', 'X', 'O') or pp.Last  like '%<mrg>%' or pp.Last  like '%DONOTUSE%' then 0 else 1 end PatientActive,


		case when pp.last in ('test', 'tests', 'ztest')  then 1 else 0 end TestPatient
		

	FROM [cpssql].CentricityPS.dbo.PatientProfile AS pp
		LEFT JOIN [cpssql].CentricityPS.dbo.MedLists marriage ON marriage.MedListsId = pp.MaritalStatusMId
		LEFT JOIN [cpssql].CentricityPS.dbo.DoctorFacility pcp ON pcp.DoctorFacilityId = pp.PrimaryCareDoctorId
		LEFT JOIN [cpssql].CentricityPS.dbo.DoctorFacility res ON res.DoctorFacilityId = pp.doctorid
		LEFT JOIN [cpssql].CentricityPS.dbo.[Language] l ON l.LanguageId = pp.LanguageId
		LEFT JOIN [cpssql].CentricityPS.dbo.MedLists emp ON emp.MedListsId = pp.EmpStatusMId
		left join CpsWarehouse.cps_all.location loc on loc.locID = pp.locationId 

		left join cpssql.CentricityPS.dbo.cusCHCPatientProfile chc on chc.PatientProfileID = pp.PatientProfileId
		LEFT JOIN [cpssql].CentricityPS.dbo.cusCRIMedLists cit ON cit.MedListsId = chc.CitizenshipMID
		LEFT JOIN [cpssql].CentricityPS.dbo.cusCRIMedLists vet ON vet.MedListsId = chc.VeteranStatusMID
		--LEFT JOIN [cpssql].CentricityPS.dbo.cusCRIMedLists so ON so.MedListsId = chc.SexualOrientationMId
		left join cpssql.Centricityps.dbo.Medlists so on so.medlistsid = pp.SexualOrientationid
		LEFT JOIN [cpssql].CentricityPS.dbo.cusCRIMedLists gi ON gi.MedListsId = chc.GenderPreferenceMId
		left join cpssql.CentricityPS.dbo.cusCHCPatientIncome inc on inc.PatientProfileID = pp.PatientProfileId and inc.enddate is null
		left join cpssql.CentricityPS.dbo.cusCHCPatientHousing hou on hou.PatientProfileID = pp.PatientProfileId and hou.enddate is null
		left join cpssql.CentricityPS.dbo.cusCRIMedLists ag on ag.MedlistsId = chc.AgriculturalWorkStatusMid

		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientCountry t2 ON t2.PatientProfileID = pp.PatientProfileId
		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientEducation t1 ON t1.PID = pp.PID
		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientProvider casemngr ON (casemngr.PID = pp.PId AND casemngr.HDID = 44679)
		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientProvider ther ON (ther.PID = pp.PId AND ther.HDID = 277131)
		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientProvider psych ON (psych.PID = pp.PId AND psych.HDID = 25290)
		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientProvider outside ON (outside.PID = pp.PId AND outside.HDID = 445575)

		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientProvider outreach ON (outreach.PID = pp.PId AND outreach.HDID = 74444)
		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientProvider hf_cm ON (hf_cm.PID = pp.PId AND hf_cm.HDID = 372826)
		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientProvider hf_sp ON (hf_sp.PID = pp.PId AND hf_sp.HDID = 372827)
		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientProvider cbcm ON (cbcm.PID = pp.PId AND cbcm.HDID = 149227)
		LEFT JOIN CpsWarehouse.cps_all.tmp_view_PatientProvider psh ON (psh.PID = pp.PId AND psh.HDID = 129621)
) 
--select * from u


	INSERT into cps_all.PatientProfile(
		SensitiveChart,PID,PatientProfileID,PatientID,[Name],[Last],[First],DoB,Phone1,Phone2,Phone3,Email,
		Sex,Zip, MaritalStatus,PCP,Facility,[LocAbbrevName],Veteran,Employment,[PatientAPI],TestPatient,
		Education,[Language],Citizenship,BirthPlace,DateOfEntry,FamilySize,AnnualIncome,LimitedEnglish,IsHomeless,IsPublicHousing,AgriculturalMigration,
		[SexualOrientation],[GenderPreference],[NotSlideFeeQualified],[SlidingFeeCurrent] ,
		[Old_CaseManager],Therapist,Psych,ExternalProvider,
		CBCM, HF_Case_Manager, HF_Housing_Specialist, Outreach,PSH,
		PatientActive, PCP_PVID, [ResponsibleProvider], [ResponsibleProvider_PVID]	)
	select 
		SensitiveChart,PID,PatientProfileID,PatientID,[Name],[Last],[First],DoB,Phone1,Phone2,Phone3,EmailAddress,
		Sex,Zip, MaritalStatus,PCP,Facility,[LocAbbrevName],Veteran,Employment,[PatientAPI],TestPatient,
		Education,[Language],Citizenship,BirthPlace,DateOfEntry,FamilySize,AnnualIncome,LimitedEnglish,IsHomeless,IsPublicHousing,AgriculturalMigration,
		[SexualOrientation],[GenderPreference],[NotSlideFeeQualified],[SlidingFeeCurrent] ,
		Old_CaseManager,Therapist,Psych,Externalprovider,
		CBCM, HF_Case_Magager, HF_Housing_Specialist, Outreach,PSH,
		PatientActive,PCP_PVID, [ResponsibleProvider], [ResponsibleProvider_PVID]
	from u;


END


go
