USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop proc if exists [cps_all].[rpt_identify_patient_insurance]
go
create proc [cps_all].[rpt_identify_patient_insurance]
(
	@patientID nvarchar(max)
)
as begin


	drop table if exists #temp
	select item
	into #temp
	from dbo.fnSplitStrings(@patientID, ',')

	select pp.PatientID, 
		ic.InsuranceName PrimaryInsurance, ins.PrimInsuranceNumber, ic.Classify_Major_Insurance PrimInsuranceGroup, 
		ic2.InsuranceName SecondaryInsurance, ins.SecInsuranceNumber, ic2.Classify_Major_Insurance SecInsuranceGroup
	from cps_all.PatientProfile pp
		inner join #temp t on t.Item = pp.PatientID
		left join cps_all.PatientInsurance ins on ins.pid = pp.PID
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.[PrimCarrierID]
		left join cps_all.InsuranceCarriers ic2 on ic2.InsuranceCarriersID = ins.SecCarrierID
end
go
--exec cps_all.rpt_identify_patient_insurance '654321,987456,123456'
go
