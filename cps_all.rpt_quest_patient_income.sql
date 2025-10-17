use CpsWarehouse
go

drop proc if exists cps_all.rpt_quest_patient_income;
go
create proc cps_all.rpt_quest_patient_income
as
begin
	select 
		pp.Name, pp.DoB, pp.Language, ic.InsuranceName PrimInsurance, pis.PrimInsuranceNumber, pis.PrimEffectiveDate, pis.PrimVerifiedDate,
		inc.AnnualIncome, convert(date,inc.LastModified) IncomeLastUpdated, med.Description IncomeSourceType,
		case when PatientSameAsGuarantor = 1 then '-'  else isnull(g.last,'') + isnull(', ' + g.first,'') end Guarantor
	from cps_all.PatientInsurance pis
		inner join cps_all.InsuranceCarriers ic on pis.PrimCarrierID = ic.InsuranceCarriersID
		left join cps_all.PatientProfile pp on pp.pid = pis.pid
		left join cpssql.CentricityPS.dbo.cusCHCPatientIncome inc on inc.PatientProfileID = pp.PatientProfileId  and inc.enddate is null and inc.LastModified >= '2021-01-01'
		left join cpssql.CentricityPS.dbo.cusCHCPatientIncomeSource src on src.cusCHCPatientIncomeID = inc.id
		left join cpssql.CentricityPS.dbo.cusCRIMedLists med on src.IncomeTypeMID = med.medListsID
		left join cpssql.CentricityPS.dbo.PatientProfile pp1 on pp.PID = pp1.PID
		left join cpssql.CentricityPS.dbo.Guarantor g on pp1.GuarantorId = g.GuarantorId
	where ic.InsuranceName like '%quest%'
		and Inactive = 0
		and pp.TestPatient = 1
END

go

