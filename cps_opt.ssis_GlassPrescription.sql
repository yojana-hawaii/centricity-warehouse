

USE CpsWarehouse
GO

SET ANSI_PADDING OFF
GO
/****** Object:  Table [cps_opt].[GlassPrescription]    Script Date: 1/29/2018 12:20:38 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop TABLE if exists [CpsWarehouse].[cps_opt].[GlassPrescription];
go
create table [CpsWarehouse].[cps_opt].[GlassPrescription] (
	[GlassID] [bigint] IDENTITY(1,1) NOT NULL,
	[PatientID] [varchar](50) NOT NULL,
	[PID] [numeric](19, 0) NOT NULL,
	[PrescriptionDate] [date] NOT NULL,
	[MasterOD] [varchar](100) NOT NULL,
	[MasterOS] [varchar](100) NOT NULL,
	[OrderedOD] [varchar](100) NOT NULL,
	[OrderedOS] [varchar](100) NOT NULL,
	[OldWayOD] [varchar](100) NOT NULL,
	[OldWayOS] [varchar](100) NOT NULL,
	[Provider] [nvarchar](100) NOT NULL,

constraint [pk_glassid] PRIMARY KEY CLUSTERED 
(
	[GlassID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO




SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop PROCEDURE if exists [cps_opt].[ssis_Glasses] 
go
CREATE PROCEDURE [cps_opt].[ssis_Glasses] 
AS BEGIN


truncate table [cps_opt].[GlassPrescription];

/*************************
Glass prescription new way
obs - 
Master prescription 
OD Sphere - 'R3 SPH OD' 
OD Cyl - 'R3 CYL OD'
OD Axis - 'R3 AXIS OD'
OD add - 'R3 ADD OD'
OD prism - 'R3 PRISM OD' 
OS Sphere - 'R3 SPH OS'
OS Cyl - 'R3 CYL OS'
OS Axis - 'R3 AXIS OS'
OS add - 'R3 ADD OS'
OS prism  - 'R3 PRISM OS'
OR
Ordered Prescription
OD Sphere - 'AR SPHR OD'
OD Cyl - 'AR CYLN OD'
OD Axis - 'AR AXIS OD'
OD Add - 'AR ADD OD'
OD Prism - 'AR PRISM OD'
OS Sphere - 'AR SPHR OS'
OS Cyl - 'AR CYLN OS'
OS Axis - 'AR AXIS OS'
OS Add - 'AR ADD OS'
OS Prism - 'AR PRISM OS'

Old way
OD - 'SPC2 PRSM OD'
OS - 'SPC2 PRSM OS'
*****************************/


with AllGlassprescriptionObs as(
	/********************************
	all master and ordered and old way prescriptions
	*********************************/
	SELECT
		pp.patientid PatientID, pp.PatientProfileId PatientProfileID,pp.PId PID,o.SDID SDID,
		oh.hdid,oh.NAME ObsTerm,o.OBSVALUE ObsValue,CONVERT(DATE,o.OBSDATE) ObsDate, df.UserName ListName
	FROM [cpssql].CentricityPS.dbo.obs o
		INNER JOIN [cpssql].CentricityPS.dbo.obshead oh on oh.hdid = o.HDID
		INNER JOIN cps_all.patientprofile pp on pp.pid= o.PID
		INNER JOIN cps_all.DoctorFacility df on df.PVId= o.PubUser
	WHERE oh.NAME IN 
		('R3 SPH OD','R3 CYL OD','R3 AXIS OD','R3 ADD OD','R3 PRISM OD',
		'R3 SPH OS','R3 CYL OS','R3 AXIS OS','R3 ADD OS','R3 PRISM OS',
		'AR SPHR OD','AR CYLN OD','AR AXIS OD','AR ADD OD','AR PRISM OD',
		'AR SPHR OS','AR CYLN OS','AR AXIS OS','AR ADD OS','AR PRISM OS',
		'SPC2 PRSM OD','SPC2 PRSM OS'
		)
), PivotPrescriptionObs as(

	/********************************
	pivot all prescriptions
	*********************************/
	SELECT *
	FROM (
		SELECT t1.pid,t1.PatientId,t1.PatientProfileId,t1.SDID,
		ObsDate,t1.ObsTerm,t1.OBSVALUE,t1.ListName AS Provider
		FROM AllGlassprescriptionObs t1

	) as a
	PIVOT
	(
		MAX(obsvalue)
		FOR ObsTerm IN 
			([R3 SPH OD],[R3 CYL OD],[R3 AXIS OD],[R3 ADD OD],[R3 PRISM OD],
			[R3 SPH OS],[R3 CYL OS],[R3 AXIS OS],[R3 ADD OS],[R3 PRISM OS],
			[AR SPHR OD],[AR CYLN OD],[AR AXIS OD],[AR ADD OD],[AR PRISM OD],
			[AR SPHR OS],[AR CYLN OS],[AR AXIS OS],[AR ADD OS],[AR PRISM OS],
			[SPC2 PRSM OD],[SPC2 PRSM OS]
			)	
	) as b
), u as (
	SELECT 
		PatientId,PID,OBSDATE AS DateOfService,
		ISNULL([R3 SPH OD], ' ')+' '+ISNULL([R3 CYL OD], ' ')+' '+ISNULL([R3 AXIS OD], ' ')+' '+ISNULL([AR ADD OD], ' ')+' '+ISNULL([R3 PRISM OD], ' ') AS MasterOD,
		ISNULL([R3 SPH OS], ' ')+' '+ISNULL([R3 CYL OS], ' ')+' '+ISNULL([R3 AXIS OS], ' ')+' '+ISNULL([R3 ADD OS], ' ')+' '+ISNULL([R3 PRISM OS], ' ')  AS MasterOS,
		ISNULL([AR SPHR OD], ' ')+' '+ISNULL([AR CYLN OD], ' ')+' '+ISNULL([AR AXIS OD], ' ')+' '+ISNULL([AR ADD OD], ' ')+' '+ISNULL([AR PRISM OD], ' ') AS OrderedOD,
		ISNULL([AR SPHR OS], ' ')+' '+ISNULL([AR CYLN OS], ' ')+' '+ISNULL([AR AXIS OS], ' ')+' '+ISNULL([AR ADD OS], ' ')+' '+ISNULL([AR PRISM OS], ' ') AS OrderedOS,
		ISNULL([SPC2 PRSM OD],'') OldWayOD,
		ISNULL([SPC2 PRSM OS],'') OldWayOS,
		Provider
	FROM PivotPrescriptionObs
	WHERE PID NOT IN (1700750880010610) --test optometry
) 

 insert into [cps_opt].[GlassPrescription] (PatientID,PID,PrescriptionDate,MasterOD,MasterOS,OrderedOD,OrderedOS,OldWayOD,OldWayOS,Provider)
 select PatientID,PID,DateOfService,MasterOD,MasterOS,OrderedOD,OrderedOS,OldWayOD,OldWayOS,Provider from u


END
GO
