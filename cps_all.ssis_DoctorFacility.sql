use CpsWarehouse
go
drop table if exists [cps_all].[DoctorFacility];
go

CREATE TABLE [cps_all].[DoctorFacility] (
    [DoctorFacilityID]    INT            NOT NULL,
    [PVID]                NUMERIC (19)   NOT NULL,
    [LastLogIn]           DATE           NULL,
    [AccountCreated]      DATE           NOT NULL,
    [Type]                VARCHAR (32)   NOT NULL,
	[Email]					varchar(50) null,
    [Inactive]            SMALLINT       NOT NULL,
    [Billable]            SMALLINT       NOT NULL,
    [CentricityUser]      SMALLINT       NOT NULL,
    [HasSchedule]         SMALLINT       NOT NULL,
    [ChartAccess]         SMALLINT       NOT NULL,
    [SignDocs]            SMALLINT       NOT NULL,
    [UserName]            NVARCHAR (100) NOT NULL,
    [ListName]            VARCHAR (160)  NOT NULL,
    [FirstName]           VARCHAR (35)   NOT NULL,
    [MiddleName]          VARCHAR (30)   NOT NULL,
    [LastName]            VARCHAR (60)   NOT NULL,
    [Suffix]              VARCHAR (20)   NULL,
    [Organization]        VARCHAR (60)   NULL,
    [JobTitle]            VARCHAR (32)   NULL,
    [Specialty]           VARCHAR (200)  NULL,
    [PreferenceGroup]     VARCHAR (24)   NULL,
    [Role]                VARCHAR (32)   NULL,
    [HomeLocation]        VARCHAR (20)   NULL,
    [CurrentLocation]     VARCHAR (20)   NULL,
    [NPI]                 VARCHAR (80)   NULL,
    [UPIN]                VARCHAR (50)   NULL,
    [FederalTaxID]        VARCHAR (50)   NULL,
    [StateLicenseNo]      VARCHAR (50)   NULL,
    [SpecialtyLicenseNo]  VARCHAR (15)   NULL,
    [AdditionalLicenseNo] VARCHAR (15)   NULL,
    [AnesthesiaLicenseNo] VARCHAR (15)   NULL,
    [DEA]                 VARCHAR (20)   NULL,
    [SPI]                 VARCHAR (36)   NULL,
    [Supervisor]          VARCHAR (160)  NULL,
    [Notes]               TEXT           NULL,
    [Address1]            VARCHAR (50)   NULL,
    [Address2]            VARCHAR (50)   NULL,
    CONSTRAINT [PK_dimDoctorFacility] PRIMARY KEY CLUSTERED ([DoctorFacilityID] ASC, [PVID] ASC, [UserName] ASC),
    UNIQUE NONCLUSTERED ([PVID] ASC),
    UNIQUE NONCLUSTERED ([UserName] ASC)
);


drop proc if exists [cps_all].[ssis_DoctorFacility];
go

CREATE PROCEDURE [cps_all].[ssis_DoctorFacility]
AS
BEGIN
truncate table cps_all.doctorfacility;

WITH u AS (
	select 
		df.DoctorFacilityId DoctorFacilityId, 
		ISNULL(df.PVId,df.DoctorFacilityId) PVID,

		CONVERT(NVARCHAR(10),CONVERT(DATE,usr.LAST_LOGIN_DATE)) LastLogIn, 
		CONVERT(DATE,df.Created) AccountCreated,

		(CASE df.Type 
			WHEN 1 THEN 'Provider'
			WHEN 6 THEN 'Schedule'
			WHEN 7 THEN 'Provider'
			WHEN 8 THEN 'Basic User'
			ELSE 'test'
			end) [Type],
		ISNULL(df.Inactive,0) Inactive,
		
		ISNULL(df.ListName,'') ListName,
		ISNULL(df.LoginUser, fxn.RemoveNonAlphaNumericCharacters(df.Listname) + convert(nvarchar(4),df.DoctorFacilityId) ) UserName,
		ISNULL(df.First,'') FirstName,ISNULL(df.Middle,'') MiddleName,ISNULL(df.Last,'') LastName, 
		case when df.Suffix in ('None','') then null else df.Suffix end Suffix,


		case when job.description = 'Information Systems' then 0
			else df.IsBillingEntity end Billable, 
		df.IsScheduleAssign HasSchedule, 
		case 
			when usr.LAST_LOGIN_DATE is null then 0 
			when DATEDIFF(MONTH, CONVERT(NVARCHAR(10),CONVERT(DATE,usr.LAST_LOGIN_DATE)), getdate() ) > 6 then 0
			else df.IsAppUser end IsAppUser,
		df.IsEmrUser IsEmrUser,
		isnull(usr.ISRESPPROV,0) ISRESPPROV,


		case 
			when df.Type = 6 then 'Schedule Resource'
			--when job.DESCRIPTION is null then ''
			else job.DESCRIPTION
		end JobTitle,

		sp.Description Specialty,
		gr.GROUPNAME PreferenceGroup,
		role.DESCRIPTION [Role],
		home.ABBREVNAME HomeLocation,
		cur.ABBREVNAME CurrentLocation,
		
		case when df.NPI = '' then null else df.NPI end NPI,
		df.UPIN UPIN,
		df.FederalTaxId FederalTaxID,
		case when df.StateLicenseNo = '' then null else df.StateLicenseNo end StateLicenseNo,
		case when df.SpecialtyLicenseNo = '' then null else df.SpecialtyLicenseNo end SpecialtyLicenseNo,
		df.AdditionalLicenseNo AdditionalLicenseNo,
		df.AnesthesiaLicenseNo AnesthesiaLicenseNo,
		case when df.DEA = '' then null else df.dea end DEA,
		case when usr.SPI = '' then null else usr.SPI end SPI,

		sup.ListName Supervisor,	
		
		df.Notes Notes,
		df.OrgName [Organization], 
		
		df.Address1 Address1, df.Address2 Address2,
		df.emailAddress [Email]

	from [cpssql].centricityps.dbo.DoctorFacility df 
		left join [cpssql].centricityps.dbo.usr on usr.pvid = df.PVId
		left join [cpssql].centricityps.dbo.MedLists sp ON sp.MedListsId = df.SpecialtyMId
		left join [cpssql].centricityps.dbo.usrgroup gr on gr.gid = df.PreferenceGroupId
		left join [cpssql].centricityps.dbo.JOBTITLE job on isnull(job.JTID, usr.jobtitle) = df.JobTitleGID
		left join [cpssql].centricityps.dbo.ROLETYPE role on role.RTID = usr.ROLELIST
		left join [cpssql].centricityps.dbo.LOCREG home ON home.LOCID = usr.HOMELOCATION
		left join [cpssql].centricityps.dbo.LOCREG cur ON cur.LOCID = usr.CURRENTLOC
		left join [cpssql].centricityps.dbo.SPECIALTYTYPE sp1 on sp1.SPID = usr.SPECIALTY
		left join [cpssql].centricityps.dbo.DoctorFacility sup on sup.PVId = usr.SUPERVISINGPROV
	where df.type not in (2,3,5)
		
) 
INSERT into cps_all.DoctorFacility 
	(LastLogIn,AccountCreated,[Type],Inactive,PVID,DoctorFacilityID,UserName,ListName,Organization,JobTitle,Specialty,PreferenceGroup,
	[Role],HomeLocation,CurrentLocation,Billable,CentricityUser,HasSchedule,ChartAccess,SignDocs,NPI,UPIN,FederalTaxID,StateLicenseNo,
	SpecialtyLicenseNo,AdditionalLicenseNo,AnesthesiaLicenseNo,DEA,SPI,Supervisor,Notes,FirstName,MiddleName,LastName,Suffix,
	Address1,Address2, [Email])
select 
	LastLogIn,AccountCreated,Type,Inactive,PVID,DoctorFacilityId,UserName,ListName,[Organization],JobTitle,Specialty,PreferenceGroup,
	Role,HomeLocation,CurrentLocation,Billable,IsAppUser,HasSchedule,IsEmrUser,ISRESPPROV,NPI,UPIN,FederalTaxID,StateLicenseNo,
	SpecialtyLicenseNo,AdditionalLicenseNo,AnesthesiaLicenseNo,DEA,SPI,Supervisor,Notes,FirstName,MiddleName,LastName,Suffix,
	Address1,Address2, [Email]
from u;

END

go
