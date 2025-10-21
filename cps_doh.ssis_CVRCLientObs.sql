
use CpsWarehouse
go
drop table if exists [cps_doh].[CVRClientObs];
go

CREATE TABLE CpsWarehouse.[cps_doh].[CVRClientObs] (
    [PID]                      NUMERIC (19)   NOT NULL,
    [PatientID]                NVARCHAR (20)  NOT NULL,
    [SDID]                     NUMERIC (19)   NOT NULL,
    [Pregnancy Intention 37-1] NVARCHAR (1)   NOT NULL,
    [Domestic Violence 41-1]   NVARCHAR (1)   NOT NULL,
    [Pregnancy Result 55-1]    NVARCHAR (1)   NOT NULL,
    [ECPPartial 56-1]          NVARCHAR (1)   NOT NULL,
    [HIV Confidential 61-1]    NVARCHAR (1)   NOT NULL,
    [CervCap 111-2 03]         NVARCHAR (2)   NOT NULL,
    [ReproHealthEd 71-1]       NVARCHAR (1)   NOT NULL,
    [InfertilityEd 72-1]       NVARCHAR (1)   NOT NULL,
    [PreconceptionEd 73-1]     NVARCHAR (1)   NOT NULL,
    [DVEd 74-1]                NVARCHAR (1)   NOT NULL,
    [ReproLifePlanEd 75-1]     NVARCHAR (1)   NOT NULL,
    [PregEd 76-1]              NVARCHAR (1)   NOT NULL,
    [AdolescentEd 77-1]        NVARCHAR (1)   NOT NULL,
    [OtherEd 78-1]             NVARCHAR (1)   NOT NULL,
    [OtherEdSpec 79-30]        NVARCHAR (30)  NOT NULL,
    [HIV/STD 109-1]            NVARCHAR (1)   NOT NULL,
    [Condom Use 110-1]         NVARCHAR (1)   NOT NULL,
    [Contraceptive 111-2]      NVARCHAR (2)   NOT NULL,
    [OtherContra 113-30]       NVARCHAR (30)  NOT NULL,
    [NoReason 143-1]           NVARCHAR (1)   NOT NULL,
    [NoMethodContra 144-30]    NVARCHAR (130) NOT NULL,
    [Tobacco 38-1]             NVARCHAR (1)   NOT NULL,
    [Alcohol 39-1]             NVARCHAR (1)   NOT NULL,
    [Drug Use 40-1]            NVARCHAR (1)   NOT NULL,
    [PHQ2 42-1]                NVARCHAR (1)   NOT NULL,
    [BMI 43-6]                 NVARCHAR (6)   NOT NULL,
    [BP 49-1]                  NVARCHAR (1)   NOT NULL,
    [IUDAdd 67-1]              NVARCHAR (1)   NOT NULL,
    [IUDRemove 68-1]           NVARCHAR (1)   NOT NULL,
    [ImplanonAdd 69-1]         NVARCHAR (1)   NOT NULL,
    [ImplanonRemove 70-1]      NVARCHAR (1)   NOT NULL,
    [Pap 51-1]                 NVARCHAR (1)   NOT NULL,
    [PelvicEx 50-1]            NVARCHAR (1)   NOT NULL,
    [TestaEx 52-1]             NVARCHAR (1)   NOT NULL,
    [ClinicBreastEx 53-1]      NVARCHAR (1)   NOT NULL,
    CONSTRAINT [PK_dimClientObsSDID] PRIMARY KEY CLUSTERED ([SDID] ASC)
);

go
drop proc if exists [cps_doh].[ssis_CVRCLientObs];
go
create PROCEDURE [cps_doh].[ssis_CVRCLientObs]
AS 
BEGIN

truncate table [cps_doh].[CVRClientObs];

--PID,PatientID,SDID,[Pregnancy Intention 37-1],[Domestic Violence 41-1],[Pregnancy Result 55-1],[ECPPartial 56-1],[HIV Confidential 61-1],[CervCap 111-2 03],
--[ReproHealthEd 71-1],[InfertilityEd 72-1],[PreconceptionEd 73-1],[DVEd 74-1],[ReproLifePlanEd 75-1],
--[PregEd 76-1],[AdolescentEd 77-1],[OtherEd 78-1],[OtherEdSpec 79-30],[HIV/STD 109-1],[Condom Use 110-1],
--[Contraceptive 111-2],[OtherContra 113-30],[NoReason 143-1],[NoMethodContra 144-30],
--[Tobacco 38-1],[Alcohol 39-1],[Drug Use 40-1],[PHQ2 42-1],[BMI 43-6],[BP 49-1],
--[IUDAdd 67-1],[IUDRemove 68-1],[ImplanonAdd 69-1],[ImplanonRemove 70-1],[Pap 51-1],
--[PelvicEx 50-1],[TestaEx 52-1],[ClinicBreastEx 53-1]

/*
HDID, Form, Type
2612, Vital Dash, Multi-select
*/

WITH u AS (
SELECT 
	PID,PatientId,SDID,

	--Family planning CUS
	(CASE WHEN [50514]	= 'Pregnancy Test + (planned)' OR [50514]	= 'Pregnancy Test - (planned)'		THEN '2'
		WHEN [50514]	= 'Pregnancy Test + (unplanned)' OR [50514]	= 'Pregnancy Test - (unplanned)'	THEN '1' ELSE ' ' END ) AS  [Pregnancy Intention 37-1],																				
	(CASE WHEN [86923] = 'No'	THEN 'N' WHEN [86923] = 'Yes'	THEN 'Y' ELSE ' ' END ) AS [Domestic Violence 41-1],
	(CASE WHEN [1012] = 'negative' THEN 'N'	 WHEN [1012] = 'positive' THEN 'P' ELSE ' ' END ) AS  [Pregnancy Result 55-1],
	(CASE WHEN [20758] IS NOT NULL THEN 'Y' ELSE ' ' END ) AS [ECPPartial 56-1],
	(CASE WHEN [45046] IS NULL THEN 'N'	 ELSE 'Y' END )	AS  [HIV Confidential 61-1],
	(CASE WHEN [5335] = 'Cervical Cap/Diaphram' THEN 'Y' ELSE 'N' END ) AS  [CervCap 111-2 03],
	(CASE WHEN [387074] IS NULL THEN 'N' ELSE 'Y' END ) AS  [ReproHealthEd 71-1],
	(CASE WHEN [296616] IS NULL THEN 'N' ELSE 'Y' END ) AS  [InfertilityEd 72-1],
	(CASE WHEN [51043] IS NULL THEN 'N'	 ELSE 'Y' END ) AS  [PreconceptionEd 73-1],
	(CASE WHEN [86923] = 'Yes' THEN 'Y'	 ELSE 'N' END ) AS [DVEd 74-1],
	(CASE WHEN [406565] IS NOT NULL	OR [16600005] LIKE '%Lifetime Reproductive Plan Discussed%'	OR [4561] LIKE '%Lifetime reproductive plan discussed%' THEN 'Y' ELSE 'N' END ) AS  [ReproLifePlanEd 75-1],
	(CASE WHEN [11918] IS NOT NULL THEN 'Y'	 ELSE 'N' END ) AS  [PregEd 76-1],
	(CASE WHEN [49181] IS NULL THEN 'N' ELSE 'Y' END ) AS  [AdolescentEd 77-1],
	(CASE WHEN [46707] IS NULL THEN 'N'	 ELSE 'Y' END ) AS  [OtherEd 78-1],
	--(CASE WHEN [46707] IS NULL THEN '                              ' ELSE LEFT(ltrim(rtrim(replace(replace([46707], char(10),' '),',',' '))) + space(60), 30) END ) AS  [OtherEdSpec 79-30],
	(CASE WHEN [46707] IS NULL THEN '                              ' ELSE LEFT(fxn.StripMultipleSpaces(replace(replace(replace([46707],char(13),' '),char(10),' '),',',' ')) + space(60), 30) END ) AS  [OtherEdSpec 79-30],
	(CASE WHEN ([4560] IS NULL	OR [6346] IS NULL) THEN 'N' ELSE 'Y' END ) AS  [HIV/STD 109-1],

	(CASE WHEN [138255] = 'yes' or [138255] = 'condom' THEN 'Y' WHEN [138255] = 'no' THEN 'N' ELSE 'N' END ) AS [Condom Use 110-1],
	(CASE 
		WHEN (ltrim(rtrim([5335])) = 'Vasectomy' OR [131310] IS NOT NULL)																				THEN '18'
		WHEN (ltrim(rtrim([5335])) = 'Female Sterlization' OR [5323] IS NOT NULL OR [2612] LIKE '%Female Sterilization%')				THEN '07'
		WHEN (ltrim(rtrim([5335])) = 'Implant' OR [132113] IS NOT NULL OR [2612] LIKE '%Norplant%')										THEN '05'
		WHEN (ltrim(rtrim([5335])) = 'Intrauterine Device Or System(IUD/IUS)' OR [35229] IS NOT NULL OR [2612] LIKE '%IUD%')										THEN '02'
		WHEN (ltrim(rtrim([5335])) = 'Lactational Amenorrhea Method (LAM)' OR [50512] IS NOT NULL)																	THEN '22'
		WHEN (ltrim(rtrim([5335])) = 'Injectable' /*OR [Depo Order] = 'Y'*/ OR [51061] IS NOT NULL OR [2612] LIKE '%Depo-Provera%')									THEN '14'
		WHEN (ltrim(rtrim([5335])) = 'Vagina Ring' /*OR [vagina ring Med] = 'Y'*/ OR [131317] IS NOT NULL)															THEN '16'
		WHEN (ltrim(rtrim([5335])) = 'Patch' /*OR [Patch Med] = 'Y'*/ OR [131315] IS NOT NULL)																		THEN '15'
		WHEN (ltrim(rtrim([5335])) = 'Oral Contraceptive (Not EC)' /*OR [Oral Contra Med] = 'Y'*/ OR [21820] IS NOT NULL OR [2612] LIKE '%Oral Contraceptives%')	THEN '11'
		WHEN (ltrim(rtrim([5335])) = 'Cervical Cap/Diaphram' OR [131316] IS NOT NULL OR [2612] LIKE '%Diaphragm%' OR [2612] LIKE '%Cervical Cap%')					THEN '03'
		WHEN (ltrim(rtrim([5335])) = 'Male Condom' OR [2887] IS NOT NULL OR [2612] LIKE '%Condoms%')																THEN '23'
		WHEN (ltrim(rtrim([5335])) = 'Female Condom' OR [67638] IS NOT NULL OR [2612] LIKE '%Condoms%')																THEN '24'
		WHEN (ltrim(rtrim([5335])) = 'Contraceptive Sponge' OR [51065] IS NOT NULL)																					THEN '17'
		WHEN (ltrim(rtrim([5335])) = 'Withdrawal' OR [67639] IS NOT NULL)																							THEN '25'
		WHEN (ltrim(rtrim([5335])) = 'Fertility Awareness Method (FAM)' OR [51067] IS NOT NULL OR [2612] LIKE '%Natural Planning%')									THEN '06'
		WHEN (ltrim(rtrim([5335])) = 'Spermicide (Used Alone)' OR [51068] IS NOT NULL OR [2612] LIKE '%Spermacide%')												THEN '09'
		WHEN (ltrim(rtrim([5335])) = 'Rely on Female Method(s)' OR [67641] IS NOT NULL)																				THEN '19'
		WHEN (ltrim(rtrim([5335])) = 'Abstinece' OR [131322] IS NOT NULL OR [2612] LIKE '%Abstinance%')																THEN '12'
		WHEN (ltrim(rtrim([5335])) = 'Other Method' OR [2612] LIKE '%Male Sterilization%' or [114718] is not null)													THEN '26'
		when ltrim(rtrim([5335])) = 'No Method'	or 	[2612] like '%None%'																							then '99'
		ELSE '00' END ) AS	 [Contraceptive 111-2],


	--(CASE WHEN [114718] IS NULL THEN '                              ' ELSE LEFT(ltrim(rtrim(replace(replace([114718], char(10),' '),',',' '))) + space(60), 30) END )	     AS	 [OtherContra 113-30],
	(CASE WHEN [114718] IS NULL THEN '                              ' ELSE LEFT(fxn.StripMultipleSpaces(replace(replace(replace([114718],char(13),' '),char(10),' '),',',' ')) + space(60), 30) END )	     AS	 [OtherContra 113-30],
	(CASE 
		WHEN [67640] = 'Pregnant/Partner Pregnant' THEN '2' 
		WHEN [67640] = 'Seeking Pregnancy' THEN '1' 
		WHEN ([67640] = ' Other Reason'
				OR [2612] LIKE '%None%' 
				or ltrim(rtrim([5335])) = 'No Method' /*selected no method*/
				or [20751] is not null /*no method thing not blank*/
			) 
			THEN '3' ELSE  ' ' END ) AS	 [NoReason 143-1]	,
	--(CASE  WHEN [20751] IS NULL THEN '                              '	 ELSE LEFT(ltrim(rtrim(replace(replace([20751], char(10),' '),',',' '))) + space(60), 30) END ) AS [NoMethodContra 144-30],
	(CASE  WHEN [20751] IS NULL THEN '                              '	 ELSE LEFT(fxn.StripMultipleSpaces(replace(replace(replace([20751],char(13),' '),char(10),' '),',',' ')) + space(60), 30) END ) AS [NoMethodContra 144-30],

	--Risk Factor CCC
	(CASE WHEN ( ([300015] IS NULL AND [130] IS NULL AND [3028] IS NULL AND [3029] IS NULL) OR [300015] IN ('smoker - current status unknown','unknown if ever smoked')) THEN 'N'
		WHEN ( [300015] IN ('current every day smoker','current some day smoker') OR [130] = 'Yes' OR [3028] = 'Yes' OR [3029] = 'Yes') THEN 'Y' ELSE ' ' END ) AS [Tobacco 38-1],
	(CASE WHEN [300014] = 'yes' OR [12882] = 'yes'	THEN 'Y' WHEN [300014] = 'no' OR [12882] = 'no' THEN 'N' ELSE ' ' END ) AS [Alcohol 39-1],
	(CASE WHEN [2315] = 'yes'	THEN 'Y' WHEN [2315] = 'no'	THEN 'N' ELSE ' ' END ) AS [Drug Use 40-1],

	--PHQ CUS										
	(CASE WHEN [65683] = 'no' OR [53333] = '0' THEN 'N'	WHEN [65683] = 'yes' OR [53333] > '0' THEN 'Y' ELSE ' '	END ) AS [PHQ2 42-1],

	--Vital Sign CCC
	(CASE WHEN [2788] IS NULL THEN '      ' ELSE RIGHT(REPLICATE('0', 6) + CAST([2788] AS VARCHAR(6)), 6) END ) AS [BMI 43-6],					
	(CASE WHEN ([53] IS NOT NULL AND [54] IS NOT NULL) THEN 'Y' ELSE 'N' END ) AS [BP 49-1],

	--OB Procedure CUS
	(CASE WHEN [35229] IS NOT NULL THEN 'Y' ELSE ' ' END )  AS  [IUDAdd 67-1],
	(CASE WHEN [35231] IS NOT NULL THEN 'Y'	ELSE ' ' END )  AS  [IUDRemove 68-1],
	(CASE WHEN [132114] = 'Insertion' THEN 'Y' ELSE ' ' END )	AS [ImplanonAdd 69-1],
	(CASE WHEN [132114] = 'Removal' THEN 'Y' ELSE ' ' END ) AS [ImplanonRemove 70-1],
			
	--Lab result
	(CASE WHEN [73] IS NOT NULL THEN 'Y' ELSE ' ' END )		AS  [Pap 51-1],
	
	--Physical Exam
	(CASE WHEN ([4675] IS NOT NULL	OR [2609] IS NOT NULL OR [2607] IS NOT NULL										--Pelvic Bladder,Pelvic Cervix,Pelvic Genital
			OR [4799] IS NOT NULL OR [2610] IS NOT NULL OR [4800] IS NOT NULL										-- Pelvic Urethra,Pelvic Adnexa,Pelvic Uterus
			OR [2608] IS NOT NULL )																					-- Pelvic Vagina
	THEN 'Y' ELSE 'N' END )		AS [PelvicEx 50-1],																-- Physical Exam . GU female
	(CASE WHEN ([4741] IS NOT NULL	OR [3112] IS NOT NULL OR [4765] IS NOT NULL)									--  Testacular Penis,Testacular Prostate,Testacular Scrotal
	THEN 'Y' ELSE 'N' END )	AS [TestaEx 52-1],																-- Physical Exam. GU male
		
	(CASE WHEN ([277004] IS NOT NULL OR [4677] IS NOT NULL)														--Physical exam. nck/chstBreast Inspection,Breast Palpation
		THEN 'Y' ELSE 'N' END )		AS [ClinicBreastEx 53-1]																	
	
FROM(
	SELECT m.PId,m.PatientId,m.SDID,obs.hdid,obs.OBSVALUE
	FROM CpsWarehouse.cps_doh.tmp_view_FindCVRPatients m
		LEFT JOIN [cpssql].[CentricityPS].dbo.OBS ON obs.SDID = m.SDID
	WHERE obs.HDID IN (131322,51067,49181,300014,50512,6346,4675,2788,53,54,277004,4677,51065,2609,3028
		,130,51061,138255,2887,45046,114718,5335,131316,86923,2315,11918,3030,20758,2607
		,67638,132113,132114,296616,35229,35231,67640,20751,21820,3029,46707,73,131315
		,4741,65683,51043,1012,50514,3112,406565,387074,4765,300015,51068,4560,5323,67641
		,4799,2610,4800,2608,131310,131317,67639,55,61,97955,12882,4561,16600005,53333,2612)
	)q
PIVOT ( 
	MAX(obsvalue)
	FOR hdid IN (
		[131322],[51067],[49181],[300014],[50512],[6346],[4675]						--ABSTIN,ABSTINENCONT,ADOLFAMPLNED,ALCOHOL COMM,AMENORRHEA,BASIC HIV ED,BLADDER PALP
		,[2788],[53],[54],[277004],[4677],[51065],[2609],[3028]						--BMI,BP DIASTOLIC,-BP SYSTOLIC,BREAST INSP,BREAST PALP,CERVCAPCONTR,CERVIX EXAM,CIGAR USE
		,[130],[51061],[138255],[2887],[45046],[114718],[5335]						--CIGARET SMKG,COMBHORMINJ,CONDOM ALWYS,CONDOM USE,CONFIDENTIAL,CONTOTHER,CONTRAC POST
		,[131316],[86923],[2315],[11918],[3030],[20758],[2607]						--DIAPH,DOMESVIO,DRUG USE,EDU PREGNAN,EDUCA LEVEL,EMERG CONTRA,EXT GEN EXAM
		,[67638],[132113],[132114],[296616],[35229],[35231]							--FEMCONDOMUSE,IMP CONT_UOC,IMP DATE_UOC,INFERTILMED1,IUDINSERTDAT ,IUDREMOVEDAT
		,[67640],[20751],[21820],[3029],[46707],[73],[131315]						--NO CONTRACEP,NOCONTRCPRSN,ORALCONTRACP,ORALTOBACUSE,OTHEREDUC,PAP SMEAR,PATCH
		,[4741],[65683],[51043],[1012],[50514],[3112],[406565]						--PENIS EXAM,PHQ9_2,PRECONCEPTED,PREG TST URN,PREGTESTRES,PROSTATEEXAM,REPRODLFPL
		,[387074],[4765],[300015],[51068],[4560],[5323],[67641]                     --REPRODSTATUS,SCROTAL EXAM,smok status,SPERMICIDCON,STD EDUC ,STERIL COUNS,UNK CONTRACP
		,[4799],[2610],[4800],[2608],[131310],[131317],[67639]                      --URETHRA EXAM,UTER ADN EXA,UTERUS PALP,VAGINA EXAM,VASECT,VRING,WITHDRAW CON
		,[55],[61],[97955],[12882],[4561],[16600005],[53333],[2612]					--Height,Weight,'FAM PLAN EDU', 'ETOH USE','CONTRACEP ED','instructions', 'PHQ-9 SCORE', birth c meth
		)
) AS p
) 


	INSERT into [cps_doh].[CVRClientObs] (PID,PatientID,SDID,[Pregnancy Intention 37-1],[Domestic Violence 41-1],
		[Pregnancy Result 55-1],[ECPPartial 56-1],[HIV Confidential 61-1],[CervCap 111-2 03],
		[ReproHealthEd 71-1],[InfertilityEd 72-1],[PreconceptionEd 73-1],[DVEd 74-1],[ReproLifePlanEd 75-1],
		[PregEd 76-1],[AdolescentEd 77-1],[OtherEd 78-1],[OtherEdSpec 79-30],[HIV/STD 109-1],[Condom Use 110-1],
		[Contraceptive 111-2],[OtherContra 113-30],[NoReason 143-1],[NoMethodContra 144-30],
		[Tobacco 38-1],[Alcohol 39-1],[Drug Use 40-1],[PHQ2 42-1],[BMI 43-6],[BP 49-1],
		[IUDAdd 67-1],[IUDRemove 68-1],[ImplanonAdd 69-1],[ImplanonRemove 70-1],[Pap 51-1],
		[PelvicEx 50-1],[TestaEx 52-1],[ClinicBreastEx 53-1])
	select 
		PID,PatientID,SDID,[Pregnancy Intention 37-1],[Domestic Violence 41-1],[Pregnancy Result 55-1],[ECPPartial 56-1],
		[HIV Confidential 61-1],[CervCap 111-2 03],
		[ReproHealthEd 71-1],[InfertilityEd 72-1],[PreconceptionEd 73-1],[DVEd 74-1],[ReproLifePlanEd 75-1],
		[PregEd 76-1],[AdolescentEd 77-1],[OtherEd 78-1],[OtherEdSpec 79-30],[HIV/STD 109-1],[Condom Use 110-1],
		[Contraceptive 111-2],[OtherContra 113-30],[NoReason 143-1],[NoMethodContra 144-30],
		[Tobacco 38-1],[Alcohol 39-1],[Drug Use 40-1],[PHQ2 42-1],[BMI 43-6],[BP 49-1],
		[IUDAdd 67-1],[IUDRemove 68-1],[ImplanonAdd 69-1],[ImplanonRemove 70-1],[Pap 51-1],
		[PelvicEx 50-1],[TestaEx 52-1],[ClinicBreastEx 53-1]
	from u;

END

go

