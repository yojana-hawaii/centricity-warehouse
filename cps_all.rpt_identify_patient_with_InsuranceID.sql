USE CpsWarehouse
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop proc if exists [cps_all].[rpt_identify_patient_with_InsuranceID]
go
create proc [cps_all].[rpt_identify_patient_with_InsuranceID]
(
	@insuranceID nvarchar(max)
)
as begin



	drop table if exists #temp
	select item
	into #temp
	from dbo.fnSplitStrings(@insuranceID, ',')

	select 
		t.Item InputInsuranceID, pp.PatientID,
		--pp.PatientID, 
		ic.InsuranceName PrimaryInsurance, ins.PrimInsuranceNumber, ic.Classify_Major_Insurance PrimInsuranceGroup, 
		ic2.InsuranceName SecondaryInsurance, ins.SecInsuranceNumber, ic2.Classify_Major_Insurance SecInsuranceGroup
	from #temp t
		left join cps_all.PatientInsurance ins on t.Item = ins.PrimInsuranceNumber or t.Item = ins.SecInsuranceNumber
		left join cps_all.PatientProfile pp on pp.pid = ins.PID
		left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.[PrimCarrierID]
		left join cps_all.InsuranceCarriers ic2 on ic2.InsuranceCarriersID = ins.SecCarrierID
end
go
--exec cps_all.rpt_identify_patient_with_InsuranceID 'a1234,b2345,c4321'

go