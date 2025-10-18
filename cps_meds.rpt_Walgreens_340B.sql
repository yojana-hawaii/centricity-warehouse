use CpsWarehouse
go



drop proc if exists cps_meds.rpt_Walgreens_340B;
go

create proc cps_meds.rpt_Walgreens_340B
(
	@StartDate date,
	@EndDate date
)
as
begin
--declare @StartDate date = '2022-01-01', @EndDate date = '2023-04-15'

--select 'Patient_ID|Last_NM|First_NM|DoB|Order_ID|Location_ID|NPI|Diagnosis_CD|Diagnosis_CD_TYP|COV_EFFECTIVE_DT|GPI|GCN'
--union
select 
	convert(varchar(20), pp.PatientID)  +'|'+ convert(varchar(25), pp.Last)  +'|'+ convert(varchar(15), pp.First)  +'|'+ convert(varchar(10), pp.DoB)  
	+'|'+ convert(varchar(64), m.PTID ) +'|'+ convert(varchar(80), loc.FacilityID)  +'|'+  convert(varchar(15), NPI)  
	+'|'+  convert(varchar(15), '') +'|'+  convert(varchar(15), '') +'|'+ convert(varchar(10), convert(date,m.ClinicalDate))
	+'|'+  convert(varchar(15), GPI) +'|'+  convert(varchar(15), '')X

	--pp.PatientID Patient_ID, pp.Last Last_NM, pp.First First_NM,pp.DoB,
	--m.PTID Order_ID,
	--loc.FacilityID Location_ID,
	--NPI,
	--'' Diagnosis_CD,
	--'' Diagnosis_CD_TYP,
	--convert(date,m.ClinicalDate) COV_EFFECTIVE_DT,
	--isnull(GPI,'') GPI, '' GCN
from cps_meds.PatientMedication m
	inner join cps_all.PatientProfile pp on pp.pid = m.PID
	inner join cps_all.DoctorFacility df on df.PVID = m.PubUser
	inner join cpssql.Centricityps.dbo.Document doc on doc.SDID = m.SDID
	inner join cps_all.Location loc on loc.locID = doc.locofcare 
where convert(date,m.ClinicalDate) >= @StartDate 
	and convert(date,m.ClinicalDate) <= @EndDate
	and TestPatient = 0
	--and loc.Facility not in ('kohou')
	and npi is not null
	and gpi is not null 
end

go

exec CpsWarehouse.cps_meds.rpt_Walgreens_340B '2022-01-01','2023-01-15';
go