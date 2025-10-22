

GO
USE CpsWarehouse
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop table if exists [CpsWarehouse].[cps_track].[papHPVTracking];
go
create table [CpsWarehouse].[cps_track].[papHPVTracking](
	[PapHpvID] [bigint] IDENTITY(1,1) NOT NULL,
	[PID] [numeric](19, 0) NOT NULL,
	[lastVisit] [date] NOT NULL,
	[lastPAPDate] [date] NULL,
	[lastPAPResult] [nvarchar](50)  NULL,
	[lastHPVDate] [date]  NULL,
	[lastHPVResult] [nvarchar](50)  NULL,
	[nextApptDate] [date]  NULL,
	[NextApptWith] [nvarchar](100) NULL,
	[yearsSinceLastPAP] [nvarchar](5)  NULL,
	[yearsSinceLastHPV] [nvarchar](5)  NULL,
	[pastDue] [nvarchar](1) NOT NULL,
	[LastElectronicResult] date null,
PRIMARY KEY CLUSTERED 
(
	[PapHpvID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]


GO






SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_track].[ssis_papHPVTracking] 
 
go
CREATE procedure [cps_track].[ssis_papHPVTracking]
as
begin

truncate table cps_track.papHPVTracking;

declare @numOfYear smallint =3;
declare @DobStart DATE = dateadd(year,-65,getdate()), 
		@dobEnd DATE = dateadd(year,-21,getdate()), 
		@visitStartDate DATETIME = dateadd(year,-@numOfYear,getdate()), 
		@visitEndDate DATETIME = getdate();

with u as (
	select 
		pp.pid,
		convert(DATE,pv.visit) LastVisit,

		(case when pap.obsvalue in ('Results Below','See Report') or pap.obsvalue is null  then null else CONVERT(DATE,pap.OBSDATE) end) LastPapDate,
		lower(case when pap.obsvalue in ('Results Below','See Report') or pap.obsvalue is null then null else pap.obsvalue end) papResult,

		(case when hpv.obsvalue in ('Results Below','See Report') or hpv.obsvalue is null  then null else CONVERT(DATE,hpv.OBSDATE) end) LastHPVDate,
		lower(case when hpv.obsvalue in ('Results Below','See Report') or hpv.obsvalue is null then null else hpv.obsvalue end) hpvResult,

		appt.ListName NextApptWith,
		convert(date,appt.apptstart) NextApptDate,

		case when pap.obsvalue in ('Results Below','See Report') or pap.obsvalue is null then null
			else convert(smallint,DATEDIFF(year,CONVERT(DATE,pap.OBSDATE),getdate()))
		end timeSinceLastPap,

		case when hpv.obsvalue in ('Results Below','See Report') or hpv.obsvalue is null then null
			else convert(smallint,DATEDIFF(year,CONVERT(DATE,hpv.OBSDATE),getdate()))
		end timeSinceLastHPV,

		convert(DATE,case 
			when hpv.obsvalue in ('Results Below','See Report') then hpv.obsdate 
			when pap.obsvalue in ('Results Below','See Report') then pap.obsdate 
			end) PAPorHPVElectronicResult

	from cps_all.PatientProfile pp
		inner join (
			select pv.patientProfileID patientProfileID, pv.visit visit,
				rowNum = ROW_NUMBER() over (partition by patientprofileID order by pv.visit desc)
			from [cpssql].CentricityPS.dbo.PatientVisit pv
			) pv ON pv.PatientProfileId = pp.PatientProfileId and pv.rowNum = 1
		left join cps_all.PatientInsurance ins ON ins.PID = pp.PID
		left join (
			select obs.pid PID, obs.obsdate obsdate, obs.obsvalue obsvalue,
				rowNum = ROW_NUMBER() over (partition by obs.pid order by obsdate desc)
			from [cpssql].CentricityPS.dbo.obs 
			where obs.HDID = 73
			) pap on pap.PID = pp.pid and pap.rowNum = 1
		left join (
			select obs.pid PID, obs.obsdate obsdate, obs.obsvalue obsvalue,
				rowNum = ROW_NUMBER() over (partition by obs.pid order by obsdate desc)
			from [cpssql].CentricityPS.dbo.obs 
			where obs.HDID = 20164
			) hpv on hpv.PID = pp.pid and hpv.rowNum = 1
		left join( 
			select ap.apptstart, df.ListName, ap.ownerID,
				RowNum = ROW_NUMBER() over (partition by ownerID order by apptstart)
			from [cpssql].CentricityPS.dbo.appointments ap 
				left join cps_all.DoctorFacility df on df.DoctorFacilityID = ap.resourceID
			where ap.apptstart >= getdate()
			) appt 
				on appt.ownerID = pp.PatientProfileID and appt.RowNum = 1
	where 
		pp.Sex = 'f' 
		AND convert(date,pp.DoB) BETWEEN @DobStart AND @dobEnd
		AND pv.Visit BETWEEN @visitStartDate AND @visitEndDate
)


, v as(
	select PID, LastVisit, LastPapDate, papResult, LastHPVDate, hpvResult, NextApptDate, NextApptWith, PAPorHPVElectronicResult,
		timeSinceLastHPV,
		timeSinceLastPap, 
		case when timeSinceLastPap < 3 then 0
			when timeSinceLastPap < 5 and timeSinceLastHPV < 5 then 0
			else 1 end PastDue
	from u
)

insert into cps_track.papHPVTracking (PID, lastVisit, lastPAPDate, lastPAPResult, yearsSinceLastPAP, lastHPVDate, lastHPVResult, yearsSinceLastHPV,nextApptDate, nextApptWith, pastDue, [LastElectronicResult])
select PID, lastVisit, lastPAPDate, PAPResult, timeSinceLastPAP, lastHPVDate, HPVResult, timeSinceLastHPV,nextApptDate, nextApptWith, pastDue, PAPorHPVElectronicResult from v



end
	
GO

