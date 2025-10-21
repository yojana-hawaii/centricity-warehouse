
use CpsWarehouse
go
drop table if exists [cps_doh].[CVRVisitClinicalList];
go
CREATE TABLE [cps_doh].[CVRVisitClinicalList] (
    [PID]                  NUMERIC (19) NOT NULL,
    [PatientID]            VARCHAR (20) NOT NULL,
    [SDID]                 NUMERIC (19) NOT NULL,
    [DoS]                  DATE         NOT NULL,
    [ClinicID 1-5]         VARCHAR (5)  NOT NULL,
    [SubID 6-2]            VARCHAR (2)  NOT NULL,
    [ClientID 8-20]        VARCHAR (20) NOT NULL,
    [DoS 28-8]             VARCHAR (8)  NOT NULL,
    [ServiceProv 36-1]     VARCHAR (1)  NOT NULL,
    [Pap 51-1]             VARCHAR (1)  NOT NULL,
    [FurtherBreast 54-1]   VARCHAR (1)  NOT NULL,
    [Chlam_test 57-1]      VARCHAR (1)  NOT NULL,
    [Chlam_Retest 58-1]    VARCHAR (1)  NOT NULL,
    [Gono_test 59-1]       VARCHAR (1)  NOT NULL,
    [Gono_Retest 60-1]     VARCHAR (1)  NOT NULL,
    [Syphi_test 62-1]      VARCHAR (1)  NOT NULL,
    [Chlam_treat 63-1]     VARCHAR (1)  NOT NULL,
    [Gono_treat 64-1]      VARCHAR (1)  NOT NULL,
    [Syphi_treat 65-1]     VARCHAR (1)  NOT NULL,
    [IUDAdd 67-1]          VARCHAR (1)  NOT NULL,
    [IUDRemove 68-1]       VARCHAR (1)  NOT NULL,
    [ImplantAdd 69-1]      VARCHAR (1)  NOT NULL,
    [ImplantRemove 70-1]   VARCHAR (1)  NOT NULL,
    [DepoPartial 111-2 14] VARCHAR (1)  NOT NULL,
    [OralContra 111-2 11]  VARCHAR (1)  NOT NULL,
    [EmergencyContra 56-1] VARCHAR (1)  NOT NULL,
    [Patch 111-2 15]       VARCHAR (1)  NOT NULL,
    [VaginaRing 111-2 16]  VARCHAR (1)  NOT NULL,
    [ProviderInitial]      VARCHAR (2)  NOT NULL,
    CONSTRAINT [PK_dimSDID] PRIMARY KEY CLUSTERED ([SDID] ASC)
);


go

drop proc if exists [cps_doh].[ssis_CVRVisitClinicalList];
go

CREATE PROCEDURE [cps_doh].[ssis_CVRVisitClinicalList]
AS 
BEGIN

truncate table [cps_doh].[CVRVisitClinicalList] 

DECLARE @OralContraMeds NVARCHAR(10) = '2599%';
DECLARE @ECPMeds NVARCHAR(10) = '2540%';
DECLARE @PatchMeds NVARCHAR(10) = '2596%';
DECLARE @VagRingmeds NVARCHAR(10) = '2597%';

declare @cptcodes table
(
dohNum int,
descriptions varchar(25),
code varchar(25)
)
insert into @cptcodes (dohNum, descriptions, code)
values 
(57, 'Chlamydia', 'CPT87110/DLS606'), (57, 'Chlamydia', 'CPT87490/DOH'), (57, 'Chlamydia', 'CPT87491/DLS484'),
(58, 'Chlamydia-rescreen', 'CPT87491/DLS484 -Re'), (58, 'Chlamydia-rescreen', 'CPT87590/DOH-Re'),
(59, 'Gonorrhea', 'CPT87590/DOH'), (59, 'Gonorrhea', 'CPT87591/DLS4337'), 
(60, 'Gonorrhea-rescreen', 'CPT87490/DOH-Re'), (60, 'Gonorrhea-rescreen','CPT87591/DLS4437-Re'),
(62, 'spyhillis', 'CPT86592/DLS695'),
(67, 'iud-add', 'CPT-58300'), 
(68, 'iud-remove',  'CPT-58301'),
(69, 'implant-add', 'CPT-11981'), (69, 'implant-add', 'CPT-11983'),
(70, 'implant-remove', 'CPT-11982'), (70, 'implant-remove', 'CPT-11983'),
(51, 'pap', 'CPT-INT88150'), (51, 'pap', 'CPT88175/HPL63120'),
(54, 'breast-eval', 'BRSTREF'),(54,'breast-eval', 'CPT-76645'),(54,'breast-eval', 'CPT-77055'),
(54, 'breast-eval', 'CPT-77056'),(54, 'breast-eval', 'CPT-77057'),(54, 'breast-eval', 'CPT-77058'),
(54, 'breast-eval', 'CPT-77059'),(54, 'breast-eval', 'CPT-G0101'),
(1112, 'depo', 'CPT-J1050'), (1112, 'depo', 'CPT-J1090');
--select * from @cptcodes;
declare @icdCodes table
(
dohNum int,
descriptions varchar(25),
code varchar(25)
)insert into @icdCodes (dohNum, descriptions, code)
values 
(63, 'Chlamydia_treatment', 'A74.9'),(63, 'Chlamydia_treatment', 'A56.01'),
(64, 'Gono_treatment', 'A54.89'), (64, 'Gono_treatment', 'A54.00'), (64, 'Gono_treatment', 'A54.1'),
(64, 'Gono_treatment', 'A54.09'), (64, 'Gono_treatment', 'A54.01'), 
(64, 'Gono_treatment', 'A54.02'), (64, 'Gono_treatment', 'A54.9'), (64, 'Gono_treatment', 'A54.29'),
(65, 'Syphillis_treatment', 'A53.9');
--select * from @icdCodes

WITH a AS(
SELECT 
	m.PID,m.SDID,m.[Provider Initial],
	MAX(CASE WHEN i.dohNum = 63 THEN 'Y' ELSE 'N' END) [Chlam_treat 63-1],
	MAX(CASE WHEN i.dohNum = 64 THEN 'Y' ELSE 'N' END) [Gono_treat 64-1],
	MAX(CASE WHEN i.dohNum = 65 THEN 'Y' ELSE 'N' END) [Syphi_treat 65-1]
FROM CpsWarehouse.cps_doh.tmp_view_FindCVRPatients m
	LEFT JOIN [cpssql].[CentricityPS].dbo.Problem pr ON pr.sdid = m.sdid
	LEFT JOIN [cpssql].[CentricityPS].dbo.MasterDiagnosis icd10 ON icd10.MasterDiagnosisId = pr.ICD10MasterDiagnosisId
	left join @icdCodes i on i.code = icd10.code
GROUP BY m.PID, m.SDID, m.[Provider Initial]
)
, b as (
select m.pid, m.sdid, 
	max(case when c.dohNum = 57 then 'Y' else 'N' END) 'Chlam_test 57-1',
	max(case when c.dohNum = 58 then 'Y' else 'N' END) 'Chlam_Re_test 58-1',
	max(case when c.dohNum = 59 then 'Y' else 'N' END) 'Gono_test 59-1',
	max(case when c.dohNum = 60 then 'Y' else 'N' END) 'Gono_re_test 60-1',
	max(case when c.dohNum = 62 then 'Y' else 'N' END) 'Syphi_test 62-1',
	max(case when c.dohNum = 67 then 'Y' else 'N' END) 'IUDAdd 67-1',
	max(case when c.dohNum = 68 then 'Y' else 'N' END) 'IUDRemove 68-1',
	max(case when c.dohNum = 69 then 'Y' else 'N' END) 'ImplantAdd 69-1',
	max(case when c.dohNum = 70 then 'Y' else 'N' END) 'ImplantRemove 70-1',
	max(case when c.dohNum = 51 then 'Y' else 'N' END) 'Pap 51-1',
	max(case when c.dohNum = 70 then 'Y' else 'N' END) 'FurtherBreast 54-1',
	max(case when c.dohNum = 1112 then 'Y' else 'N' END) 'DepoPartial 111-2 14'
FROM CpsWarehouse.cps_doh.tmp_view_FindCVRPatients m
	LEFT JOIN [cpssql].[CentricityPS].dbo.ORDERS o ON o.sdid = m.sdid
	left join @cptcodes c on c.code = o.code
group by m.pid, m.sdid
)
/* From medication GPI
 * oral contraceptive - @OralContraMeds
 * Emergency patch management - @ECPMeds
 * patch - @PatchMeds
 * Vagina Ring - @VagRingmeds
 */
,c AS (
	SELECT m.pid,m.sdid,--meds.DESCRIPTION,
		ISNULL(MAX(CASE WHEN meds.GPI LIKE @OralContraMeds THEN 'Y' ELSE 'N' END), 'N') [OralContra 111-2 11],
		ISNULL(MAX(CASE WHEN meds.GPI LIKE @ECPMeds THEN 'Y' ELSE 'N' END), 'N') [EmergencyContra 56-1],
		ISNULL(MAX(CASE WHEN meds.GPI LIKE @PatchMeds THEN 'Y' ELSE 'N' END), 'N') [Patch 111-2 15],
		ISNULL(MAX(CASE WHEN meds.GPI LIKE @VagRingmeds THEN 'Y' ELSE 'N' END), 'N') [VaginaRing 111-2 16]
	FROM CpsWarehouse.cps_doh.tmp_view_FindCVRPatients m
		LEFT JOIN  [cpssql].[CentricityPS].dbo.MEDICATE meds ON meds.SDID = m.sdid
	WHERE meds.GPI like (@OralContraMeds)
		OR meds.GPI like (@ECPMeds)
		OR meds.GPI like (@PatchMeds)
		OR meds.GPI like (@VagRingmeds)
	GROUP BY m.pid, m.sdid
)
, u AS (
select DISTINCT
	m.pid, m.PatientId, m.sdid, ISNULL(CONVERT(DATE,pv.visit),CONVERT(DATE,m.DB_CREATE_DATE) ) AS DoS,
	'19001'AS [ClinicID 1-5],
	(CASE m.LoC WHEN 'Dowtown' THEN '02' WHEN 'Kaaahi' THEN '03' WHEN 'Living Well' THEN '05' WHEN '710' THEN '04' ELSE '01' END) 'SubID 6-2',
	RIGHT(REPLICATE('0', 20) + CAST(pp.PatientId AS VARCHAR(20)), 20)  AS [ClientID 8-20],
	ISNULL(REPLACE(CONVERT(VARCHAR(10), pv.visit, 101), '/', ''), REPLACE(CONVERT(VARCHAR(10), m.DB_CREATE_DATE, 101), '/', '') ) AS [DoS 28-8],
	(CASE WHEN RIGHT(REPLICATE('0', 2) + CAST(m.Suffix AS VARCHAR(2)), 2) = 'MD'	THEN '1'
		WHEN RIGHT(REPLICATE('0', 4) + CAST(m.Suffix AS VARCHAR(4)), 4) = 'APRN'	THEN '2'
		WHEN RIGHT(REPLICATE('0', 3) + CAST(m.Suffix AS VARCHAR(3)), 3) = 'CNM'		THEN '2'
		WHEN RIGHT(REPLICATE('0', 2) + CAST(m.Suffix AS VARCHAR(2)), 2) = 'PA'		THEN '2'
		ELSE '4'	END) AS [ServiceProv 36-1],
	ISNULL(b.[Pap 51-1],'N') AS [Pap 51-1],
	ISNULL(b.[FurtherBreast 54-1],'N') AS [FurtherBreast 54-1],
	ISNULL(b.[Chlam_test 57-1],'N') AS [Chlam_test 57-1], 
	isnull(b.[Chlam_Re_test 58-1],'N') AS [Chlam_Retest 58-1],
	ISNULL(b.[Gono_test 59-1],'N') AS [Gono_test 59-1], 
	ISNULL(b.[Gono_re_test 60-1] ,'N') AS [Gono_Retest 60-1],
	ISNULL(b.[Syphi_test 62-1],'N') AS [Syphi_test 62-1],
	ISNULL(a.[Chlam_treat 63-1],'N') AS [Chlam_treat 63-1],
	ISNULL(a.[Gono_treat 64-1],'N') AS [Gono_treat 64-1],
	ISNULL(a.[Syphi_treat 65-1],'N') AS [Syphi_treat 65-1],
	ISNULL(b.[IUDAdd 67-1],'N') AS [IUDAdd 67-1],
	ISNULL(b.[IUDRemove 68-1],'N') AS [IUDRemove 68-1],
	ISNULL(b.[ImplantAdd 69-1],'N') AS [ImplantAdd 69-1],
	ISNULL(b.[ImplantRemove 70-1],'N') AS [ImplantRemove 70-1],
	ISNULL(b.[DepoPartial 111-2 14],'N') AS [DepoPartial 111-2 14],
	ISNULL(c.[OralContra 111-2 11],'N') AS [OralContra 111-2 11],
	ISNULL(c.[EmergencyContra 56-1],'N') AS [EmergencyContra 56-1],
	ISNULL(c.[Patch 111-2 15],'N') AS [Patch 111-2 15],
	ISNULL(c.[VaginaRing 111-2 16],'N') AS [VaginaRing 111-2 16], 
	m.[Provider Initial]
from CpsWarehouse.cps_doh.tmp_view_FindCVRPatients m
	INNER JOIN CpsWarehouse.cps_all.PatientProfile pp ON pp.pid = m.pid
	LEFT JOIN [cpssql].[CentricityPS].dbo.PatientVisit pv ON m.patientvisitID = pv.PatientVisitId
	left join a on a.SDID = m.SDID
	left join b on m.sdid = b.sdid
	left join c on m.sdid = c.sdid
) --select * from u where sdid = 1875974550193400

	INSERT into [cps_doh].[CVRVisitClinicalList] 
		([PID],[PatientID],[SDID],[DoS],[ClinicID 1-5],[SubID 6-2],[ClientID 8-20],[DoS 28-8],[ServiceProv 36-1],[Pap 51-1],
		[FurtherBreast 54-1],[Chlam_test 57-1],[Chlam_Retest 58-1],[Gono_test 59-1],[Gono_Retest 60-1],[Syphi_test 62-1],[Chlam_treat 63-1],
		[Gono_treat 64-1],[Syphi_treat 65-1],[IUDAdd 67-1],[IUDRemove 68-1],[ImplantAdd 69-1],[ImplantRemove 70-1],[DepoPartial 111-2 14],
		[OralContra 111-2 11],[EmergencyContra 56-1],[Patch 111-2 15],[VaginaRing 111-2 16],[ProviderInitial])
	select [PID],[PatientID],[SDID],[DoS],[ClinicID 1-5],[SubID 6-2],[ClientID 8-20],[DoS 28-8],[ServiceProv 36-1],[Pap 51-1],
		[FurtherBreast 54-1],[Chlam_test 57-1],[Chlam_Retest 58-1],[Gono_test 59-1],[Gono_Retest 60-1],[Syphi_test 62-1],[Chlam_treat 63-1],
		[Gono_treat 64-1],[Syphi_treat 65-1],[IUDAdd 67-1],[IUDRemove 68-1],[ImplantAdd 69-1],[ImplantRemove 70-1],[DepoPartial 111-2 14],
		[OralContra 111-2 11],[EmergencyContra 56-1],[Patch 111-2 15],[VaginaRing 111-2 16],[Provider Initial]
	from u;



END

go
