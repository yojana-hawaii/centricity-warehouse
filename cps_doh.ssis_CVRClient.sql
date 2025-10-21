
use CpsWarehouse
go

drop table if exists [cps_doh].[CVRClient];
go

CREATE TABLE [cps_doh].[CVRClient] (
    [PID]           NUMERIC (19)  NOT NULL,
    [ClinicID]      NVARCHAR (5)  NOT NULL,
    [SubID]         NVARCHAR (2)  NOT NULL,
    [ClientID]      NVARCHAR (20) NOT NULL,
    [Sex]           NVARCHAR (1)  NOT NULL,
    [DoB]           NVARCHAR (8)  NOT NULL,
    [Zip]           NVARCHAR (9)  NOT NULL,
    [Race]          NVARCHAR (1)  NOT NULL,
    [Ethnicity]     NVARCHAR (1)  NOT NULL,
    [PovertyLevel]  NVARCHAR (3)  NOT NULL,
    [FamilySize]    NVARCHAR (2)  NOT NULL,
    [MonthlyIncome] NVARCHAR (4)  NOT NULL,
    [Black]         NVARCHAR (1)  NOT NULL,
    [Amr_Ind]       NVARCHAR (1)  NOT NULL,
    [White]         NVARCHAR (1)  NOT NULL,
    [Portugese]     NVARCHAR (1)  NOT NULL,
    [Pot_Mex]       NVARCHAR (1)  NOT NULL,
    [Chinese]       NVARCHAR (1)  NOT NULL,
    [Filipino]      NVARCHAR (1)  NOT NULL,
    [Japanese]      NVARCHAR (1)  NOT NULL,
    [Korean]        NVARCHAR (1)  NOT NULL,
    [Vietnamese]    NVARCHAR (1)  NOT NULL,
    [Hawaiian]      NVARCHAR (1)  NOT NULL,
    [Samoan]        NVARCHAR (1)  NOT NULL,
    [Marshallese]   NVARCHAR (1)  NOT NULL,
    [Micronesian]   NVARCHAR (1)  NOT NULL,
    [Chuuk]         NVARCHAR (1)  NOT NULL,
    [Korsa]         NVARCHAR (1)  NOT NULL,
    [Pohn]          NVARCHAR (1)  NOT NULL,
    [Yap]           NVARCHAR (1)  NOT NULL,
    [Unknown]       NVARCHAR (1)  NOT NULL,
    [Oth_Asian]     NVARCHAR (1)  NOT NULL,
    [Oth_AFree]     NVARCHAR (30) NOT NULL,
    [Oth_OPI]       NVARCHAR (1)  NOT NULL,
    [Oth_PFree]     NVARCHAR (30) NOT NULL,
    [Other]         NVARCHAR (1)  NOT NULL,
    [Oth_Free]      NVARCHAR (30) NOT NULL,
    [Education]     NVARCHAR (1)  NOT NULL,
    [English]       NVARCHAR (1)  NOT NULL,
    [CompactFree]   NVARCHAR (1)  NOT NULL,
    [Insurance]     NVARCHAR (1)  NOT NULL,
    [Confidential]  NVARCHAR (1)  NOT NULL,
    CONSTRAINT [PK_dohPatientID] PRIMARY KEY CLUSTERED ([ClientID] ASC, [SubID] ASC)
);

go

drop proc if exists [cps_doh].[ssis_CVRClient];
go
CREATE PROCEDURE [cps_doh].[ssis_CVRClient]
AS 
BEGIN

truncate table cps_doh.[CVRClient];

	WITH u AS(
		SELECT 
			DISTINCT pp.PID,'19001' 'ClinicID 1-5',
			CASE m.LoC 
				WHEN 'Dowtown' THEN '02' 
				WHEN 'Kaaahi' THEN '03' 
				WHEN 'Living Well' THEN '05' 
				WHEN '710' THEN '04' 
				ELSE '01' 
			END 'SubID 6-2',

			RIGHT(REPLICATE('0', 20) + CAST(pp.PatientId AS VARCHAR(20)), 20)  'ClientID 8-20',
			pp.Sex 'Sex 28-1', 	
			REPLACE(CONVERT(VARCHAR(10), pp.DoB, 101), '/', '') AS 'DoB 29-8',	
			(LEFT(pp.Zip, 5) + '    ') AS 'Zip 37-9',

			(CASE 	
				WHEN (Race1 != '' and Race2 != '') or (SubRace1 != '' and SubRace2 != '') then 6 /*more than one race*/
				WHEN race1 = 'American Indian or Alaska Native' THEN 1
				WHEN race1 = 'Asian' THEN 2
				WHEN race1 = 'Black or African American' THEN 3
				WHEN race1 = 'Native Hawaiian or Other Pacific Islander' THEN 4
				WHEN race1 = 'White' THEN 5
				WHEN race1 = 'Unspecified' THEN 7
				ELSE 0
			END) AS 'Race 46-1', 
			
			(CASE Ethnicity1
				WHEN 'Hispanic or Latino' THEN 'Y' 
				WHEN 'Not Hispanic or Latino' THEN 'N' 
			ELSE 'U' END) AS 'Ethnicity 47-1', 

			'   ' AS 'PovertyLevel 48-3',
			ISNULL(RIGHT(REPLICATE('0', 2) + CAST(pp.FamilySize AS VARCHAR(2)), 2),'  ') AS 'FamilySize 51-2',
			ISNULL(RIGHT(REPLICATE('0', 4) + CAST(pp.AnnualIncome / 12 AS VARCHAR(4)), 4),'    ') AS 'MonthlyIncome 53-4',
	
			(CASE WHEN SubRace1 = 'Black or African American' OR SubRace2 = 'Black or African American' THEN 'Y' ELSE 'N' END) AS 'Black 57-1',
			(CASE WHEN SubRace1 = 'American Indian or Alaska Native' OR SubRace2 = 'American Indian or Alaska Native' THEN 'Y' ELSE 'N' END) AS 'AMR_IND 58-1',
			(CASE WHEN SubRace1 = 'White' OR SubRace2 = 'White' THEN 'Y' ELSE 'N' END) AS 'White 59-1',
			'N' AS 'Portugese 60-1',	'N' AS 'Porto_Mex 61-1',
			(CASE WHEN SubRace1 = 'Chinese' OR SubRace2 = 'Chinese' THEN 'Y' ELSE 'N' END) AS 'Chinese 62-1',
			(CASE WHEN SubRace1 = 'Filipino' OR SubRace2 = 'Filipino' THEN 'Y' ELSE 'N' END) AS 'Filipino 63-1',
			(CASE WHEN SubRace1 = 'Japanese' OR SubRace2 = 'Japanese' THEN 'Y' ELSE 'N' END) AS 'Japanese 64-1',
			(CASE WHEN SubRace1 = 'Korean' OR SubRace2 = 'Korean' THEN 'Y' ELSE 'N' END) AS 'Korean 65-1',
			(CASE WHEN SubRace1 = 'Vietnamese' OR SubRace2 = 'Vietnamese' THEN 'Y' ELSE 'N' END) AS 'Vietnamese 66-1',
			(CASE WHEN SubRace1 = 'Native Hawaiian' OR SubRace2 = 'Native Hawaiian' THEN 'Y' ELSE 'N' END) AS 'Hawaiian 67-1',
			(CASE WHEN SubRace1 = 'Samoan' OR SubRace2 = 'Samoan' THEN 'Y' ELSE 'N' END) AS 'Samoan 68-1',
			(CASE WHEN SubRace1 = 'Marshallese' OR SubRace2 = 'Marshallese' THEN 'Y' ELSE 'N' END) AS 'Marshallese 69-1',
			'N' AS 'Mic 70-1',
			(CASE WHEN SubRace1 = 'Chuukese' OR SubRace2 = 'Chuukese' THEN 'Y' ELSE 'N' END) AS 'Chuuk 71-1',
			'N' AS 'Korsa 72-1',	'N' AS 'Pohn 73-1',	'N' AS 'Yap 74-1',
			(CASE WHEN SubRace1 = 'Unspecified' OR SubRace2 = 'Unspecified' THEN 'Y' ELSE 'N' END) AS 'Unknown 75-1',
			(CASE WHEN SubRace1 IN ('Asian','Laotian','Other Asian') 
				OR SubRace2 IN ('Asian','Laotian','Other Asian') THEN 'Y' ELSE 'N' END) AS 'Oth_A 76-1',
			'                              ' AS 'Oth_AFree 77-30',
			(CASE WHEN SubRace1 IN ('Other Pacific Islander','Native Hawaiian or Other Pacific Islander','Chamorro','Tongan') 
				OR SubRace2 IN ('Other Pacific Islander','Native Hawaiian or Other Pacific Islander','Chamorro','Tongan') THEN 'Y' ELSE 'N' END) AS 'Oth_P 107-1',
			'                              ' AS 'Oth_PFree 108-30',	'N' AS 'Other 138-1','                              ' AS 'Oth_Free 139-30',

			(CASE pp.Education 
				WHEN 'Bachelor or Higher' THEN '5' 
				WHEN 'Associate' THEN '4' 
				WHEN 'Some College' THEN '3'
				WHEN 'High School Graduate / GED' THEN '2' 
				WHEN '< High School' THEN '1' 
			ELSE ' ' END) 'Education 169-1',

			(CASE pp.LimitedEnglish 
				WHEN 1 THEN 'Y'	ELSE 'N'	
			END) 'EnglishProficiency 170-1',

			(CASE 	
				WHEN race.subrace1 LIKE 'Marshallese%' OR race.SubRace2 LIKE 'Marshallese%' THEN '1'
				WHEN race.subrace1 LIKE 'Chuukese%' OR race.SubRace2 LIKE 'Chuukese%' THEN '2'	
			ELSE '5'	END) AS 'CompactFree 171-1',

			(CASE ic.Classify_DoH_CVR WHEN 'Uninsured' THEN '1' WHEN 'Public' THEN '2' WHEN 'Private' THEN '3' WHEN 'Military' THEN '4' ELSE ' ' END) 'Insurance 172-1', 
			(CASE pp.SensitiveChart WHEN 1 THEN 'Y' ELSE 'N' END) 'Confidential 173-1'
		FROM CpsWarehouse.[cps_doh].tmp_view_FindCVRPatients m
			LEFT JOIN CpsWarehouse.cps_all.PatientProfile pp ON pp.pid = m.pid
			left join CpsWarehouse.[cps_all].PatientRace race on race.PID = pp.PID
			left join CpsWarehouse.cps_all.PatientInsurance ins on ins.pid = pp.PID
			left join CpsWarehouse.cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.PrimCarrierID
			--LEFT JOIN [cpssql].[CentricityPS].dbo.PatientVisit pv ON m.patientvisitID = pv.PatientVisitId
	)


		INSERT into cps_doh.[CVRClient] (PID, ClinicID, SubID, ClientID,
			Sex,DoB, Zip,Race,Ethnicity,PovertyLevel,FamilySize,MonthlyIncome,
			Black,Amr_Ind,White, Portugese,	Pot_Mex,Chinese,Filipino,Japanese,Korean,
			Vietnamese,Hawaiian,Samoan,Marshallese,Micronesian,Chuuk,Korsa,Pohn,Yap,
			Unknown,Oth_Asian,Oth_AFree,Oth_OPI,Oth_PFree,Other,Oth_Free,
			Education,English,CompactFree,Insurance,Confidential)
		select
			PID, [ClinicID 1-5],[SubID 6-2], [ClientID 8-20],
			[Sex 28-1],[DoB 29-8],[Zip 37-9],[Race 46-1],[Ethnicity 47-1],[PovertyLevel 48-3],[FamilySize 51-2],[MonthlyIncome 53-4],
			[Black 57-1],[Amr_Ind 58-1],[White 59-1],[Portugese 60-1],[Porto_Mex 61-1],[Chinese 62-1],[Filipino 63-1],[Japanese 64-1],[Korean 65-1],
			[Vietnamese 66-1],[Hawaiian 67-1],[Samoan 68-1],[Marshallese 69-1],[Mic 70-1],[Chuuk 71-1],[Korsa 72-1],[Pohn 73-1],[Yap 74-1],
			[Unknown 75-1],[Oth_A 76-1],[Oth_AFree 77-30],[Oth_p 107-1],[Oth_PFree 108-30],[Other 138-1],[Oth_Free 139-30],
			[Education 169-1],[EnglishProficiency 170-1],[CompactFree 171-1],[Insurance 172-1],[Confidential 173-1]
		from u;

END

go

