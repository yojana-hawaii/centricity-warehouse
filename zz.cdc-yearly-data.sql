
use CpsWarehouse
go

declare @StartDate date = '2023-04-01', @EndDate date = '2023-06-30'

drop table if exists #majority;
select distinct 
	pvt.pid, pvt.PatientVisitID,ic.InsuranceName, pvt.InsuranceIDUSed,
	pp.First, pp1.Middle, pp.Last,
	pp1.Address1, pp1.Address2, pp1.City, pp1.State, pp.Zip,pp1.ssn,
	pp.Phone1, case when pp.Email like '%@x.y' then null else pp.Email end Email, 
	pp.Sex Gender, pp.PatientID,
	race.Ethnicity1, isnull(race.Race1, 'Other /  unspecified') Race1, isnull(Race2,'') race2,
	pp.MaritalStatus, pp.DoB, 
	df.ListName Providers, df.NPI, df.Specialty,
	
	convert(date,pvt.DoS) DateOfService, --pvt.ICD10, pvt.CPTCode,
	v.BMI, v.BP_Diastolic, v.BP_Systolic, v.Height_Inches, v.Weight_lbs, v.Temperature_F,
	v.Chief_Complaint VisitReason,
	ldl.LDL, a1c.HGBA1C, ld.Lead_Screening

into #majority
from cps_visits.PatientVisitType pvt
	left join cps_all.PatientProfile pp on pp.pid = pvt.PID
	left join cpssql.centricityps.dbo.PatientProfile pp1 on pp1.pid = pvt.PID
	left join cps_all.PatientRace race on pp.pid = race.PID
	left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = pvt.InsuranceCarrierUsed
	left join cps_all.DoctorFacility df on df.DoctorFacilityID = pvt.ApptProviderID
	left join cps_visits.PatientVisitType_Join_Document d on d.PatientVisitID = pvt.PatientVisitID
	left join cps_obs.VitalSignFlowsheet v on v.SDID = d.SDID
	left join cps_obs.LabsFlowsheet ldl on ldl.pid = pvt.PID 
							and DATEDIFF(day, pvt.DoS, ldl.ObsDate) < 10 
							and DATEDIFF(day, pvt.DoS, ldl.ObsDate) > 5 
							and ldl.LDL is not null 
							and ldl.LDL not in ('NOT REPORTABLE mg/dL','Trig>400. LDL not valid. mg/dL')
	left join cps_obs.LabsFlowsheet a1c on a1c.pid = pvt.PID 
							and DATEDIFF(day, pvt.DoS, a1c.ObsDate) < 10 
							and DATEDIFF(day, pvt.DoS, a1c.ObsDate) > 5 
							and a1c.HGBA1C is not null
							and a1c.HGBA1C not in ('Wrong test ordered.')
	left join cps_obs.LabsFlowsheet ld on ld.pid = pvt.PID 
							and DATEDIFF(day, pvt.DoS, ld.ObsDate) < 10 
							and DATEDIFF(day, pvt.DoS, ld.ObsDate) > 5 
							and ld.Lead_Screening is not null
							--and a1c.HGBA1C not in ('Wrong test ordered.')
where pvt.DoS >= @StartDate 
	and pvt.DoS <= @EndDate
	and (MedicalVisit = 1  or OptVisit = 1)

select * from #majority

select 
	m.PID, m.PatientVisitID, d.Code ICD10Code, d.description ICD10Desc, 
	case when listOrder = 1 then '*' else '' end PrimaryICD 
from #majority m 
	left join cpssql.centricityps.dbo.patientvisitdiags d  on m.patientVisitID= d.patientVisitID

select m.PID, m.PatientVisitID, d.CPTCode, d.Description CPTDesc
from #majority m 
	left join cpssql.centricityps.dbo.PatientVisitProcs d  on m.patientVisitID= d.patientVisitID

