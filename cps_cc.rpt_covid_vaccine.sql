

use CpsWarehouse
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
drop proc if exists cps_cc.rpt_covid_vaccine

go

create proc cps_cc.rpt_covid_vaccine
(
	@outside varchar(5) = NULL,
	@fed varchar(5) = NULL
)
with recompile
as 
begin
	--	declare @outside varchar(5) = 'All', @fed varchar(5) = 'fed';
	set @outside = case when @outside = 'All' then null else @outside end;
	set @fed = case when @fed = 'fed' then 1 else null end;
	--select @outside, @fed;


	;with u as (
		select pp.patientid, 
			pp.Name, pp.DoB, pp1.Address1, pp1.Address2, pp1.City, pp1.State, pp.Zip, 
			pp.Sex, pp.Language, pp.AgeRounded Age, 
			race.Race1, race.Race2, race.Ethnicity1, race.Ethnicity2,
			race.SubRace1, race.SubRace2,
			imm.AdministeredDate, imm.AdministeredBy, imm.Brand, imm.VaccineSite, 
			imm.LotNumber, imm.ExpirationDate ExpDate, imm.Series, 
			imm.Historical outside, imm.HistoricalSource outside_Source,
			--isnull(sup.Supplier,'Not Sure') Supplier,
			case 
				when sup.Supplier = 'fed' then 1
				when sup.Supplier = 'state' then 0
				else -1
			end Supplier,
			pp.AgriculturalMigration, pp.IsHomeless, pp.IsPublicHousing, pp.LimitedEnglish, 
			
			case 
				when imm.VFCEligibility = 'v01' then 'Not VFC Eligible'
				when imm.VFCEligibility = 'v02' then 'VFC Eligible - medicaid / medicare'
				when imm.VFCEligibility = 'v03' then 'VFC Eligible - uninsured'
				when imm.VFCEligibility = 'v04' then 'VFC Eligible - american indian or alaska'
				when imm.VFCEligibility = 'v05' then 'VFC Eligible - fqhc underinsured'
				when imm.VFCEligibility = 'v06' then 'VFC Eligible - state specific eligibility'
				when imm.VFCEligibility = 'v07' then 'VFC Eligible - local specific'
				when imm.VFCEligibility = 'v08' then 'VFC Eligible - underinsured'
				when imm.VFCEligibility = 'v25' then 'VFC Eligible - state program eligibility'

				else VFCEligibility end
			VFCEligibility , 
			isnull(imm.FundingSource,'') FundingSource, 
			isnull(ic.InsuranceName,'') InsuranceName, imm.LoC
		from cps_imm.ImmunizationGiven imm
			left join cps_all.PatientProfile pp on pp.pid = imm.PID
			left join cps_all.PatientRace race on race.PID = imm.PID
			left join cps_cc.Covid_Vaccine_Supplier sup on sup.LotNumber = imm.LotNumber
			left join cpssql.CentricityPS.dbo.PatientProfile pp1 on pp1.pid = imm.pid
			left join cps_all.PatientInsurance ins on ins.pid = imm.PID
			left join cps_all.InsuranceCarriers ic on ins.PrimCarrierID = ic.InsuranceCarriersID
		where cvxcode in (207,208,210,212,218,217,219,229,300,213,301,302,309,310,308,312,311)
	)
		select * from u
		where outside = isnull(@outside, outside)
		and Supplier = isnull(@fed, Supplier) 

end

go 

