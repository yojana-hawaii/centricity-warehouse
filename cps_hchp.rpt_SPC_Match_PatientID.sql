

USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop proc if exists cps_hchp.rpt_SPC_Match_PatientID
go
create proc cps_hchp.rpt_SPC_Match_PatientID
(
	@patientID nvarchar(max),
	@StartDate date,
	@EndDate date
)
as begin
	--declare @patientID nvarchar(max) = '8376000,12112838,2475400,12109021,12047775,12071814', @StartDate date = '2021-01-01', @EndDate date = '2021-02-01'


	drop table if exists #temp
	select item
	into #temp
	from fxn.SplitStrings(@patientID, ',')

	select pp.PatientID, pp.Name, convert(date, pvt.DoS) DoS,-- pvt.BilledProvider, df.ListName EnablingResource, pvt.CPTCode, 
		case when agg.OrigInsAllocation > agg.InsPayment then agg.OrigInsAllocation else agg.InsPayment end BillableCharge--,
		--agg.OrigInsAllocation
		--ic.InsuranceName PrimaryInsurance, ins.PrimInsuranceNumber, ic.Classify_Major_Insurance PrimInsuranceGroup, 
		--ic2.InsuranceName SecondaryInsurance, ins.SecInsuranceNumber, ic2.Classify_Major_Insurance SecInsuranceGroup
	from cps_all.PatientProfile pp
		inner join #temp t on t.Item = pp.PatientID
		left join cps_visits.PatientVisitType pvt on pvt.pid = pp.PID and pvt.DoS >= @StartDate and pvt.DoS <= @EndDate
		left join [cpssql].[CentricityPS].dbo.PatientVisitAgg agg on agg.PatientVisitid = pvt.PatientVisitID
		left join cps_all.DoctorFacility df on df.DoctorFacilityID = pvt.Resource1
	where pvt.MedicalVisit = 1 or pvt.BHVisit = 1 or OptVisit = 1
end
go