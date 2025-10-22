
use [CpsWarehouse]
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop table if exists [CpsWarehouse].[cps_den].[DentalPatientProfile];
GO
create table [CpsWarehouse].[cps_den].[DentalPatientProfile](
	PatID int not null primary key,
	Chart varchar(20) not null UNIQUE,
	LastName varchar(21) null,
	FirstName varchar(16) null,
	MiddleName varchar(2) null,
	Gender varchar(40) null,
	DoB date null, 
	Ethnicity varchar(25) null,
	Race varchar(25) null,
	[Language] varchar(25) null,
	Street varchar(60) null,
	Street2 varchar(60) null,
	Zip varchar(15) null,
	Married varchar(9) null,
	Phone1 varchar(17) null,
	Phone2 varchar(17) null,
	Phone3 varchar(17) null,
	Active smallint null,
	PrimProvLast varchar(21) null,
	PrimProvFirst varchar(16) null,
	PrimInsurance varchar(32) null,
	PriminsID varchar(31) null,
	EffectiveDate date null,
	ExpirationDate date null,
	LastVerified date null,
	MissedAppt int null,
	LastMissedAppt date null,
	FirstVisitDate date null,
	LastVisitDate date null,
	LoC  varchar(10) null,
	HomeLess varchar(22) null,
	WorkStatus varchar(25) null,
	Veteran int null,

) 

GO


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_den].[ssis_DentalPatientProfile] 

go
create procedure [cps_den].[ssis_DentalPatientProfile]
as begin

truncate table cps_den.DentalPatientProfile;

with u as (
	select  
		pp.patID,pp.CHART, pp.LASTNAME, pp.FIRSTNAME, pp.MI MiddleName,
		ltrim(rtrim(sex.DESCRIPTION)) AS Gender,

		convert(date,pp.BIRTHDATE) DoB, 
		ltrim(rtrim(eth.DESCRIPTION)) AS Ethnicity,
		ltrim(rtrim(race.DESCRIPTION)) AS Race,
		ltrim(rtrim(lang.DESCRIPTION)) AS Language,
		addr.STREET, addr.STREET2, addr.ZIP, 
		case pp.FAMPOS when 1 then 'Single' when 2 then 'Married' when 3 then 'Child' 
			when 4 then 'Other' when 5 then 'Widowed' when 6 then 'Divorced'
			when 7 then 'Separated' end Married,
		pp.WKPHONE,
		pp.OTHERPHONE,pp.HOMEPHONE Phone,
		case pp.STATUS when 1 then 1 when 2 then -1 when 3 then 0 end Active,

		prov.NAME_LAST ProvLast, prov.NAME_FIRST ProvFirst,
		ltrim(rtrim(insurance.INSCONAME)) PrimInsurance,
		ltrim(rtrim(insured.IDNUM)) PrimInsID,
		convert(date,insured.EffectiveDate) EffectiveDate , 
		convert(date,insured.ExpirationDate) ExpirationDate, 
		convert(date,insured.LAST_VERIFIED) LastVerified,
		pp.MISSEDAPPT, 
		convert(date,pp.LASTMISSEDAPPT) LastMissedAppt,
		convert(date,pp.FIRSTVISITDATE) FirstVisitDate,
		convert(date, pp.lastVisitDate) lastVisitDate,
	
		lower(case clinic.URSCID when 30 then '915' else clinic.RSCID end ) LoC,
		ltrim(rtrim(homeless.DESCRIPTION)) AS Homeless,
		ltrim(rtrim(work.DESCRIPTION)) AS WorkStatus,
		pp.Veteran
	FROM [den_sql].Dentrix.dbo.DDB_PAT_BASE AS pp 
		left join [den_sql].Dentrix.dbo.DDB_INSURED_BASE insured on insured.INSUREDID = pp.PRINSUREDID
		left join [den_sql].Dentrix.dbo.DDB_INSURANCE_base insurance on insurance.insid = insured.INSID
		left join [den_sql].Dentrix.dbo.DDB_CLINIC_INFO clinic on clinic.URSCID = pp.DefaultClinic
		left join [den_sql].Dentrix.dbo.DDB_DEF_TEXT race on race.DEFID = pp.Race and race.type = 100
		left join [den_sql].Dentrix.dbo.DDB_DEF_TEXT lang on lang.DEFID = pp.Language and lang.type = 101
		left join [den_sql].Dentrix.dbo.DDB_DEF_TEXT eth on eth.DEFID = pp.EthnicityID and eth.type = 115
		left join [den_sql].Dentrix.dbo.DDB_DEF_TEXT sex on sex.DEFID = pp.GENDER and sex.type = 124
		left join [den_sql].Dentrix.dbo.DDB_DEF_TEXT homeless on homeless.DEFID = pp.HomelessStatus and homeless.type = 110
		left join [den_sql].Dentrix.dbo.DDB_DEF_TEXT work on work.DEFID = pp.WorkerStatus and work.type = 109
		left join [den_sql].Dentrix.dbo.ddb_rsc prov on prov.URSCID = pp.PRPROVID
		left join [den_sql].Dentrix.dbo.DDB_ADDRESS_BASE addr on pp.ADDRESSID = addr.ADDRESSID
) 
--	select * into #temp from u
--	exec tempdb.dbo.sp_help N'#temp'
--	drop table #temp
insert CpsWarehouse.cps_den.DentalPatientProfile
	(
		[PatID],[Chart],[LastName],[FirstName],[MiddleName],[Gender],[DoB],
		[Ethnicity],[Race],[Language],[Street],[Street2],[Zip],[Married],[Phone1],
		[Phone2],[Phone3],[Active],[PrimProvLast],[PrimProvFirst],[PrimInsurance],
		[PriminsID],[EffectiveDate],[ExpirationDate],[LastVerified],[MissedAppt],
		[LastMissedAppt],[FirstVisitDate],[LastVisitDate],[LoC],[HomeLess],[WorkStatus],[Veteran]
	)

	select 
		[PatID],[Chart],[LastName],[FirstName],[MiddleName],[Gender],[DoB],
		[Ethnicity],[Race],[Language],[Street],[Street2],[Zip],[Married],[WKPhone],
		[OtherPhone],[Phone],[Active],[ProvLast],[ProvFirst],[PrimInsurance],
		[PriminsID],[EffectiveDate],[ExpirationDate],[LastVerified],[MissedAppt],
		[LastMissedAppt],[FirstVisitDate],[LastVisitDate],[LoC],[HomeLess],[WorkStatus],[Veteran]
	from u
end 
go
