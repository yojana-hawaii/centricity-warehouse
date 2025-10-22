

USE [CpsWarehouse]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop table if exists [CpsWarehouse].cps_track.[patientPortalSignup];
go
create table [CpsWarehouse].cps_track.[patientPortalSignup](
	[ppSignupID] [bigint] IDENTITY(1,1) primary key NOT NULL,
	[stat] [tinyint] NOT NULL,
	[PID] [numeric](19, 0) NULL,
	[CPSName] [nvarchar](100) NOT NULL,
	[ppName] [nvarchar](100) NOT NULL,
	[ppEmail] [nvarchar](100) NOT NULL,
	[ppCreationDate] [date] NOT NULL,
	[pinNumber] [nvarchar](25) NOT NULL,
	[pinDate] [date] NOT NULL,
	[noOfPinGenerated] [smallint] NOT NULL,
	[pinCreator] [numeric](19, 0) NOT NULL,
) ON [PRIMARY]

GO




drop PROCEDURE if exists cps_track.[ssis_patientPortalSignup]
go

create procedure cps_track.[ssis_patientPortalSignup]
as begin

truncate table  [CpsWarehouse].cps_track.[patientPortalSignup];
with z as(
	select 
		--DCommunity.Name, 
		KUser.LastName + ', ' + KUser.FirstName Name, pp.PID, pp.Facility, pp.PCP, 
		KUser.Description [Description], DPartner.ServiceType, 
		KEmailAddress.EmailAddress [EmailAddress], KUser.CreationDate [CreationDate], 
		DPartner.Identifier ID, KEmailAddress.IsDefault, KEmailAddress.HasValidatedEmail
	from [cpssql].Enterprise.dbo.KEmailAddress as [KEmailAddress]
		INNER JOIN 
		(
			--(
				(
					[cpssql].Enterprise.dbo.DCommunityAccount as [DCommunityAccount]
					LEFT OUTER JOIN [cpssql].Enterprise.dbo.DPartner as [DPartner] ON DCommunityAccount.DCommunityAccountKey=DPartner.DCommunityAccountKey
				) 
				--INNER JOIN [cpssql].Enterprise.dbo.DCommunity as [DCommunity] ON DCommunityAccount.DCommunityKey=DCommunity.DCommunityKey
			 --) 
			INNER JOIN [cpssql].Enterprise.dbo.KUser as [KUser] ON DCommunityAccount.UserID=KUser.UserID
		) on KEmailAddress.UserID=KUser.UserID 
		left join cps_all.PatientProfile pp on pp.PatientProfileID =  DPartner.Identifier

	where (DPartner.ServiceType IS NULL OR DPartner.ServiceType=2) 
		AND KEmailAddress.EmailAddress NOT LIKE '%@x.y' 
		and KEmailAddress.EmailAddress NOT LIKE '%@y.z'
		AND (KUser.Name IS NOT NULL OR KEmailAddress.EmailAddress NOT LIKE '%@%direct%') 
		AND KEmailAddress.IsDefault=1 
		and KUser.LastName != 'test'
)

, a as(
select 	pp.PID, pp.PatientProfileID, pp.Last + ', ' + pp.First Name , obs.OBSVALUE PinNumber, obs.obsdate PinGeneratedDate, 
	df.pvid PinCreater, RowNum =ROW_NUMBER() over (partition by pp.PID order by obsdate desc)
from [cpssql].centricityps.dbo.OBS
	left join [cpssql].centricityps.dbo.document doc on doc.SDID = OBS.SDID
	left join cps_all.PatientProfile pp on pp.PID = obs.pid
	left join cps_all.DoctorFacility df on df.PVID = obs.usrid	
	--left join [cpssql].centricityps.dbo.locreg l on l.LOCID = doc.LOCOFCARE
where HDID = 126280 and pp.Last != 'Test'
)
, b as(
	select PID, COUNT(*) NoOfPINGenerated
	from a
	group by PID
)
, c as(
	select a.PID, a.PatientProfileID, a.Name, a.PinNumber, a.PinGeneratedDate, a.PinCreater, b.NoOfPINGenerated
	from a, b
	where a.PID = b.PID and a.RowNum = 1
)
, d as (
	select 
		convert(varchar(1),
			case 
				when c.PID is not null and z.PID is not null then 1 
				when c.PID is not null  then 2
				when c.PID is null and z.PID is null then 4
				else 3 end) Stat, 
		isnull((case when c.PID is not null then c.PID else z.PID end ),0) PID,
		isnull(c.Name,'') CPSName, 
		isnull(z.Name,'') PPName, 
		isnull(z.description,'') PPDescription,
		isnull(z.EmailAddress,'') PPEmail,
		convert(date,isnull(z.CreationDate,'')) PPCreationDate,
		isnull(c.PinNumber,'') CPSPinNumber, 
		ISNULL(c.NoOfPINGenerated,'') NoOfPINGenerated,
		convert(date,isnull(c.PinGeneratedDate,'')) PinGeneratedDate, 
		isnull(c.PinCreater,0) CPSPinCreater
	from z
		full outer join c on c.PID = z.PID
)

insert into  [CpsWarehouse].cps_track.[patientPortalSignup] (stat,PID,CPSName,ppName,ppEmail,ppCreationDate,pinNumber,pinDate,noOfPinGenerated,pinCreator)
select stat,PID,CPSName,ppName,ppEmail,ppCreationDate,CPSpinNumber,pinGeneratedDate,noOfPinGenerated,CPSpinCreater
from d


end

GO
