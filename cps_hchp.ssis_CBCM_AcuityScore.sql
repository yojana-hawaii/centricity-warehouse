USE CpsWarehouse
GO 

DROP TABLE if exists cps_hchp.CBCM_AcuityScore;
go
CREATE TABLE cps_hchp.CBCM_AcuityScore (
	[PID] [numeric](19, 0) NOT NULL,
	[AcuityDate] [date] NULL,
	[AcuityScore] [smallint] NULL,
	[AcuityCount] [smallint] NOT NULL,
	[PsychHospitalCount] [varchar](10) NULL,
	[Interpretation] [varchar](50) NULL,
	[VisitPerMonth] [int] NULL,
	[VisitType] [varchar](50) NOT NULL,
	[EncounterType] [varchar](50) NOT NULL,
	[Years] [smallint] NOT NULL,
	[January] [smallint] NOT NULL,
	[February] [smallint] NOT NULL,
	[March] [smallint] NOT NULL,
	[April] [smallint] NOT NULL,
	[May] [smallint] NOT NULL,
	[June] [smallint] NOT NULL,
	[July] [smallint] NOT NULL,
	[August] [smallint] NOT NULL,
	[September] [smallint] NOT NULL,
	[October] [smallint] NOT NULL,
	[November] [smallint] NOT NULL,
	[December] [smallint] NOT NULL
) ON [PRIMARY]


GO


drop PROCEDURE if exists  [cps_hchp].[ssis_CBCM_AcuityScore] 
 
go
CREATE PROCEDURE [cps_hchp].[ssis_CBCM_AcuityScore]
AS BEGIN
truncate table cps_hchp.CBCM_AcuityScore;

with allCBCMData as (
	--All CBCM data - acuity score, visits (face to face, collateral, telephone) and psych hospital visit and type (amhd,ccs,enabling and dischange)
	 select pp.pid, ObsDate Obsdate,
			MAX(CASE WHEN HDID = 298426 THEN OBSVALUE END )  EncounterType,
			MAX(CASE WHEN HDID = 66473 THEN OBSVALUE END )  VisitType,
			MAX(CASE WHEN HDID = 462650 THEN OBSVALUE END )  AcuityScore,
			MAX(CASE WHEN HDID = 190483 THEN OBSVALUE END )  Hospital
	 from cps_hchp.HCHP_Patient_Appointments pp
		left  join [cpssql].[CentricityPS].[dbo].OBS on (obs.pid = pp.pid and obs.HDID IN (462650,298426,66473,190483) )

	-- where cbcm  = 1
	group by pp.PID,OBSDATE

)
, psychHospital as (
	--separate psych hospital visits
	SELECT  
		a.PID, a.ObsDate HospitalDate, a.Hospital
	FROM allCBCMData AS a
	where a.Hospital is not null
)
--	select * from psychHospital
, acuityScore as (
	-- separate acuity scores
	SELECT  
		a.PID, a.ObsDate AcuityDate, a.AcuityScore,
		(CASE WHEN  a.AcuityScore >= 71  THEN 'Level 4: 8 per month'  
			WHEN  a.AcuityScore >= 35  THEN 'Level 3: 4 per month'  
			WHEN  a.AcuityScore >= 21  THEN 'Level 2: 2 per month'  
		ELSE 'Level 1: 1 per month'	END) Interpretation,
		AcuityCount = ROW_NUMBER() OVER (PARTITION BY PID ORDER BY OBSDATE ASC)
	FROM allCBCMData AS a
	WHERE a.AcuityScore IS NOT NULL
)
--	select * from acuityScore
, encounterType as (
	--separate encounter
	SELECT  
		a.PID, a.ObsDate EncounterDate, a.EncounterType
	FROM allCBCMData AS a
	WHERE a.EncounterType IS NOT NULL
)
--	select * from encounterType
, visitType as (
	--separate visits
	SELECT  
		a.PID, a.ObsDate VisitDate, a.VisitType
	FROM allCBCMData AS a
	WHERE a.VisitType IS NOT NULL
)
--	select * from visitType
, minMax as (
	--find the min and max date of acuity score for each pts
	SELECT 
		PID, MAX(acuitydate) maxDate, MIN(acuityDate) minDate 
	FROM acuityScore a
	GROUP BY PID
)
--	select * from minMax
,allPIDVisitandEncounter as (
select  distinct case when v.pid is not null then v.pid else e.pid end PID
from visitType v
	full outer join encounterType e on e.pid = v.pid
)
, allPIDAcuity as (
select distinct PID from acuityScore
)
, acuityStartEndDate  as (
	--acuity dates with 1900 as first and 2100 as last and everything in between are normal dates	
	SELECT * 
	FROM  (
	 --has visit between acuity score
	SELECT b1.PID, b1.AcuityDate AS AcuityStart, b1.AcuityScore,
		b2.AcuityDate AS AcuityEnd,	b1.Interpretation, b1.AcuityCount
	FROM acuityScore b1
		INNER JOIN acuityScore b2 ON  b1.PID = b2.PID  
	WHERE b1.AcuityCount + 1 = b2.AcuityCount 
	UNION 
	-- visits before acuity scores were calculated
	SELECT  b3.PID, '1900-01-01' AcuityStart, NULL AS AcuityScore, b3.AcuityDate AcuityEnd, NULL as Interpretation, 0  AS AcuityCount
	FROM acuityScore b3
	WHERE b3.AcuityCount = 1
	UNION 
	-- visits after last acuity scores were calculated
	SELECT  a.PID, a.AcuityDate AS AcuityStart, a.AcuityScore, '2100-01-01' AS AcuityEnd, a.Interpretation, a.AcuityCount
	FROM acuityScore a
		INNER JOIN minMax m ON a.PID = m.PID AND m.maxDate = a.AcuityDate
	UNION
	-- visits with no acuity score ever
	select a.PID, '1900-01-01' AcuityStart,NULL AS AcuityScore,'2100-01-01' AS AcuityEnd, NULL as Interpretation, 0  AS AcuityCount
	from allPIDVisitandEncounter a 
	left join allPIDAcuity b on a.pid = b.pid 
	where b.pid is null
	) t
)
, addHospitalToAcuity as (
select a.PID, a.AcuityStart, acuityScore, AcuityCount, acuityend, Interpretation, count(h.Hospital) psychHospital
from acuityStartEndDate a
	LEFT JOIN psychHospital h on (h.PID = a.PID AND CONVERT(DATE,h.HospitalDate) >= CONVERT(date,a.AcuityStart) and convert(date,h.HospitalDate) < convert(date,a.AcuityEnd) and h.Hospital = 'yes')
group by a.PID, a.AcuityStart, acuityScore, acuityend, Interpretation,AcuityCount
)
, visitBetweenAcuity as (
	--find place visits in between acuity score dates
	SELECT 
		t.PID,t.AcuityStart, t.AcuityScore, t.AcuityEnd, 
		t.Interpretation,PsychHospital,
		(case when psychHospital > 0 then 8
			WHEN Interpretation = 'Level 1: 1 per month' THEN 1 
			WHEN Interpretation = 'Level 2: 2 per month' THEN 2 
			WHEN Interpretation = 'Level 3: 4 per month' THEN 4 
			WHEN Interpretation = 'Level 4: 8 per month' THEN 8 
			ELSE null END ) VisitPerMonth,
		t.AcuityCount,t.DoS,t.VisitType,t.EncounterType, 
		YEAR(t.DoS) 'Years', DATENAME(MONTH,t.DoS) 'Months'
	FROM ( 
		SELECT distinct
			a.PID,CONVERT(DATE,a.AcuityStart) AcuityStart,a.AcuityScore,CONVERT(DATE,a.AcuityEnd) AcuityEnd,a.Interpretation, a.acuityCount,
			convert(date, case when v.VisitDate is not null then v.VisitDate else e.EncounterDate end) DoS, 
			v.VisitType,e.EncounterType, a.psychHospital
		FROM addHospitalToAcuity a
			LEFT JOIN visitType v ON v.PID = a.PID AND v.VisitDate >= a.AcuityStart AND v.VisitDate < a.AcuityEnd
			LEFT JOIN encounterType e ON (e.PID = a.PID 
								AND e.EncounterDate >= a.AcuityStart 
								AND e.EncounterDate < a.AcuityEnd 
								and e.EncounterDate = v.VisitDate)
		) t
) 

, u as (
select 
	pid,  nullif(AcuityStart,'1900-01-01') AcuityDate, AcuityScore,AcuityCount, PsychHospital, 
	Interpretation, VisitPerMonth, isnull(visitType,'') VisitType, isnull(EncounterType,'') EncounterType, isnull(Years,0) Years, 
	January, February, March, April, May, June, July, August, September, October, November, December
from
	(	
	select pid, psychHospital, 	AcuityStart, AcuityScore, Interpretation, AcuityCount, AcuityEnd, visitType, EncounterType, Years, 
		VisitPerMonth,Months
	from visitBetweenAcuity
	) AS s
	PIVOT (
		COUNT(Months)
		FOR [Months] IN (January,February,March,April,May,June,July,August,September,October,November,December)
	) as pvt
where not (years is  null and VisitPerMonth is  null)
)
--select distinct pid from u
 insert into cps_hchp.CBCM_AcuityScore (PID,AcuityDate,AcuityCount,AcuityScore,PsychHospitalCount,Interpretation,VisitPerMonth,VisitType,EncounterType,
	Years,January,February,March,April,May,June,July,August,September,October,November,December) 
select PID,AcuityDate,AcuityCount,AcuityScore,PsychHospital,Interpretation,VisitPerMonth,VisitType,EncounterType,
	Years,January,February,March,April,May,June,July,August,September,October,November,December
from u

end

GO
