
USE CpsWarehouse
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
drop TABLE if exists [CpsWarehouse].[cps_opt].[ContactPrescription];
go
create table [CpsWarehouse].[cps_opt].[ContactPrescription] (
	[ContactID] [bigint] IDENTITY(1,1) NOT NULL,
	[PatientID] [varchar](50) NOT NULL,
	[PID] [numeric](19, 0) NOT NULL,
	[PrescriptionDate] [date] NOT NULL,
	[Provider] [nvarchar](100) NOT NULL,
	[FinalOD] [varchar](150) NOT NULL,
	[FinalOS] [varchar](150) NOT NULL,
	[FinalOU] [varchar](150) NOT NULL,
	[TrialOD] [varchar](150) NOT NULL,
	[TrialOS] [varchar](150) NOT NULL,
	[OldWayOD] [varchar](150) NOT NULL,
	[OldWayOS] [varchar](150) NOT NULL,
	[OldWayOU] [varchar](150) NOT NULL,
	[OldWayTrialOD] [varchar](150) NOT NULL,
	[OldWayTrialOS] [varchar](150) NOT NULL,
constraint [pk_contactID] PRIMARY KEY CLUSTERED 
(
	[ContactID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_opt].[ssis_Contact];
 
go
CREATE PROCEDURE [cps_opt].[ssis_Contact]
AS BEGIN

truncate table [cps_opt].[ContactPrescription];

/*************************
Contact prescription new way
obs  
Final prescription 
OD
Sphere -"O.D. BASE","MFR SPH OD","SPEC SPHR OD"
Cyl - "MFR CYL OD","R2 CYL OD"
Axis - "CL AXIS OD"
Add - "CL ADD OD"
Dist - "VA C REF OD"
DorN - "VIS C NEAROD"
Checkbox - "VIS COR OD"
Brand - "cl brand od"
Weartime - "VI AC PIN OD"
DIA - "TITMUS1"
BC - "SPEC READ OD"
Color - "COLOR OD"
Order -  "PH OD"
OS
Sphere - "O.S. BASE","MFR SPH OS","SPEC SPHR OS"
Cylinder -"MFR CYL OS","R2 CYL OS",
Axis - "CL AXIS OS"
Add - "CL ADD OS"
Dist - "VA C REF OS"
DorN - "VIS C NEAROS"
Checkbox - "VIS COR OS"
Brand - "cl brand os"
Weartime - "VI AC PIN OS"
DIA - "TITMUS2"
BC - "SPEC READ OS"
Color - "COLOR OS"
Order - "PH OS"
OU  
Dist- "VIS CR DS OU"
Near - "VIS UC NR OU"
CL Solution - "CUR SOL"

//Trial OD 
'RET OD','REFR SPHE OD','RET MISC OD','RET CYL OD','REFR CYL OD',
'AXIS OD','ADD OD','VA UC NR OD','VIS C NR OD','VS CR DS OD',
'VIS CR NR OD','VIS UC DS OD','TFBUT OD','READ COMP OD','COLR VIS OD'
//OS 
'RET OS','REFR SPHE OS','RET MISC OS','RET CYL OS','REFR CYL OS'
'AXIS OS','ADD OS','VA UC NR OS','VIS C NR OS','VIS CR DS OS'
'VIS CR NR OS','VIS UC DS OS','TFBUT OS','READ COMP OS','COLR VIS OS'

Old way contact
OD - CL POWER OD
OS - CL POWER OS
OU -  CL DIAM OD
old way trial
OD - OPTICNERVEOD
OS -OPTICNERVEOS

*****************************/

/********************************
all prescribed contact obs 
*********************************/
with AllContactObs as (
	SELECT 
		pp.patientid, pp.PatientProfileId,pp.PId,obs.SDID,
		oh.hdid,oh.NAME,obs.OBSVALUE,CONVERT(DATE,obs.OBSDATE) PrescriptionDate, df.UserName Provider
	FROM [cpssql].CentricityPS.dbo.obs obs
		INNER JOIN [cpssql].CentricityPS.dbo.obshead oh on oh.hdid = obs.HDID
		INNER JOIN cps_all.patientprofile pp on pp.pid= obs.PID
		INNER JOIN cps_all.doctorfacility df on df.pvid= obs.pubuser
	WHERE oh.NAME IN 
		(
		'O.D. BASE','MFR SPH OD','SPEC SPHR OD','MFR CYL OD','R2 CYL OD','CL AXIS OD','CL ADD OD','VA C REF OD','VIS C NEAROD','VIS COR OD','cl brand od','VI AC PIN OD','TITMUS1','SPEC READ OD','COLOR OD','PH OD', /*Prescription OD*/
		'O.S. BASE','MFR SPH OS','SPEC SPHR OS','MFR CYL OS','R2 CYL OS','CL AXIS OS','CL ADD OS','VA C REF OS','VIS C NEAROS','VIS COR OS','cl brand os','VI AC PIN OS','TITMUS2','SPEC READ OS','COLOR OS','PH OS', /*Prescription OS*/
		'VIS CR DS OU','VIS UC NR OU','CUR SOL', /*OU*/
		'RET OD','REFR SPHE OD','RET MISC OD','RET CYL OD','REFR CYL OD','AXIS OD','ADD OD','VA UC NR OD','VIS C NR OD','VS CR DS OD','VIS CR NR OD','VIS UC DS OD','TFBUT OD','READ COMP OD','COLR VIS OD', /*Trial OD*/
		'RET OS','REFR SPHE OS','RET MISC OS','RET CYL OS','REFR CYL OS','AXIS OS','ADD OS','VA UC NR OS','VIS C NR OS','VIS CR DS OS','VIS CR NR OS','VIS UC DS OS','TFBUT OS','READ COMP OS','COLR VIS OS', /*Trial OS*/
		'CL POWER OD','CL POWER OS','CL DIAM OD', /*old way prescription*/
		'OPTICNERVEOD','OPTICNERVEOS' /*old way trial*/
		)
)
/********************************
pivot master and ordered prescriptions
*********************************/
, PivotContactPrescriptionObs as (
	SELECT *
	FROM (
		SELECT t1.pid PID,t1.PatientId PatientID,t1.PatientProfileId,t1.SDID,
		t1.PrescriptionDate,t1.Provider,t1.NAME,t1.OBSVALUE
		FROM AllContactObs t1
	) as a
	PIVOT
	(
		MAX(obsvalue)
		FOR name IN 
			([O.D. BASE],[MFR SPH OD],[SPEC SPHR OD],[MFR CYL OD],[R2 CYL OD],[CL AXIS OD],[CL ADD OD],[VA C REF OD],[VIS C NEAROD],[VIS COR OD],[cl brand od],[VI AC PIN OD],[TITMUS1],[SPEC READ OD],[COLOR OD],[PH OD],
			[O.S. BASE],[MFR SPH OS],[SPEC SPHR OS],[MFR CYL OS],[R2 CYL OS],[CL AXIS OS],[CL ADD OS],[VA C REF OS],[VIS C NEAROS],[VIS COR OS],[cl brand os],[VI AC PIN OS],[TITMUS2],[SPEC READ OS],[COLOR OS],[PH OS],
			[VIS CR DS OU],[VIS UC NR OU],[CUR SOL],
			[RET OD],[REFR SPHE OD],[RET MISC OD],[RET CYL OD],[REFR CYL OD],[AXIS OD],[ADD OD],[VA UC NR OD],[VIS C NR OD],[VS CR DS OD],[VIS CR NR OD],[VIS UC DS OD],[TFBUT OD],[READ COMP OD],[COLR VIS OD],
			[RET OS],[REFR SPHE OS],[RET MISC OS],[RET CYL OS],[REFR CYL OS],[AXIS OS],[ADD OS],[VA UC NR OS],[VIS C NR OS],[VIS CR DS OS],[VIS CR NR OS],[VIS UC DS OS],[TFBUT OS],[READ COMP OS],[COLR VIS OS],
			[CL POWER OD],[CL POWER OS],[CL DIAM OD],[OPTICNERVEOD],[OPTICNERVEOS]
			)	
	) as b
)
, u as (
	SELECT 
		PatientId, PID,PrescriptionDate,Provider,
		ISNULL([O.D. BASE],' ') + ' ' +ISNULL([MFR SPH OD],' ') + ' ' +ISNULL([SPEC SPHR OD],' ') + ' ' +ISNULL([MFR CYL OD],' ') + ' ' +ISNULL([R2 CYL OD],' ') + ' ' +
		ISNULL([CL AXIS OD],' ') + ' ' +ISNULL([CL ADD OD],' ') + ' ' +ISNULL([VA C REF OD],' ') + ' ' +ISNULL([VIS C NEAROD],' ') + ' ' +ISNULL([VIS COR OD],' ') + ' ' +
		ISNULL([cl brand od],' ') + ' ' +ISNULL([VI AC PIN OD],' ') + ' ' +ISNULL([TITMUS1],' ') + ' ' +ISNULL([SPEC READ OD],' ') + ' ' +ISNULL([COLOR OD],' ') + ' ' +ISNULL([PH OD],' ')  AS FinalOD,
		ISNULL([CL AXIS OS],' ') + ' ' +ISNULL([MFR SPH OS],' ') + ' ' +ISNULL([SPEC SPHR OS],' ') + ' ' +ISNULL([MFR CYL OS],' ') + ' ' +ISNULL([R2 CYL OS],' ') + ' ' +
		ISNULL([CL AXIS OS],' ') + ' ' +ISNULL([CL ADD OS],' ') + ' ' +ISNULL([VA C REF OS],' ') + ' ' +ISNULL([VIS C NEAROS],' ') + ' ' +ISNULL([VIS COR OS],' ') + ' ' +
		ISNULL([cl brand os],' ') + ' ' +ISNULL([VI AC PIN OS],' ') + ' ' +ISNULL([TITMUS2],' ') + ' ' +ISNULL([SPEC READ OS],' ') + ' ' +ISNULL([COLOR OS],' ') + ' ' +ISNULL([PH OS],' ') AS FinalOS,
		ISNULL([VIS CR DS OU],' ') + ' ' +ISNULL([VIS UC NR OU],' ') + ' ' +ISNULL([CUR SOL],' ') AS FinalOU,
	
		ISNULL([RET OD],' ') + ' ' +ISNULL([REFR SPHE OD],' ') + ' ' +ISNULL([RET MISC OD],' ') + ' ' +ISNULL([RET CYL OD],' ') + ' ' +ISNULL([REFR CYL OD],' ') + ' ' +
		ISNULL([AXIS OD],' ') + ' ' +ISNULL([ADD OD],' ') + ' ' +ISNULL([VA UC NR OD],' ') + ' ' +ISNULL([VIS C NR OD],' ') + ' ' +ISNULL([VS CR DS OD],' ') + ' ' +
		ISNULL([VIS CR NR OD],' ') + ' ' +ISNULL([VIS UC DS OD],' ') + ' ' +ISNULL([TFBUT OD],' ') + ' ' +ISNULL([READ COMP OD],' ') + ' ' +ISNULL([COLR VIS OD],' ') AS TrialOD,
		ISNULL([RET OS],' ') + ' ' +ISNULL([REFR SPHE OS],' ') + ' ' +ISNULL([RET MISC OS],' ') + ' ' +ISNULL([RET CYL OS],' ') + ' ' +ISNULL([REFR CYL OS],' ') + ' ' +
		ISNULL([AXIS OS],' ') + ' ' +ISNULL([ADD OS],' ') + ' ' +ISNULL([VA UC NR OS],' ') + ' ' +ISNULL([VIS C NR OS],' ') + ' ' +ISNULL([VIS CR DS OS],' ') + ' ' +
		ISNULL([VIS CR NR OS],' ') + ' ' +ISNULL([VIS UC DS OS],' ') + ' ' +ISNULL([TFBUT OS],' ') + ' ' +ISNULL([READ COMP OS],' ') + ' ' +ISNULL([COLR VIS OS],' ') AS TrialOS,
		ISNULL([CL POWER OD],' ') OldWayFinalOD, ISNULL([CL POWER OS],' ')OldWayFinalOS, ISNULL([CL DIAM OD],' ') AS OldWayFinalOU,
		ISNULL([OPTICNERVEOD],' ') OldWayTrialOD, ISNULL([OPTICNERVEOS],' ') AS OldWayTrialOS
	FROM PivotContactPrescriptionObs
	WHERE PID NOT IN (1700750880010610) AND PatientId NOT IN (12059493,12023079)
)


	INSERT into [cps_opt].[ContactPrescription] (PatientID,PID,PrescriptionDate,Provider,FinalOD,FinalOS,FinalOU,TrialOD,TrialOS,OldWayOD,OldWayOS,OldWayOU,OldWayTrialOD,OldWayTrialOS)
	select PatientID,PID,PrescriptionDate,Provider,FinalOD,FinalOS,FinalOU,TrialOD,TrialOS,OldWayFinalOD,OldWayFinalOS,OldWayFinalOU,OldWayTrialOD,OldWayTrialOS from u


end

go
