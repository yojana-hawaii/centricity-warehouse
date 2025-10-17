
use CpsWarehouse
go

drop table if exists [cps_all].[InsuranceCarriers];
go
CREATE TABLE [cps_all].[InsuranceCarriers] (
    [InsuranceCarriersID]                     INT           NOT NULL,
    [Inactive]                                BIT           NOT NULL,
    [InsuranceName]                           VARCHAR (60)  NOT NULL,
    [InsuranceGroup]                          VARCHAR (50)  NULL,
    [Classify_Major_Insurance]				  NVARCHAR (20) NOT NULL,
    [Classify_DoH_CVR]						  NVARCHAR (20) NOT NULL,
    [Classify_Meaningful_Use]				  NVARCHAR (20) NOT NULL,

    [CarrierType]                             VARCHAR (200) NULL,
    [FinancialClass]                          VARCHAR (200) NULL,
    [FilingMethod]                            VARCHAR (200) NULL,
    [FilingType]                              VARCHAR (200) NULL,
    [InsurancePolicyType]                     VARCHAR (200) NULL,
	[ClaimClearingHouse]                     VARCHAR (200) NULL, 
	[ClaimPayerId]                     VARCHAR (200) NULL,
	[ClaimPlugin]                     VARCHAR (200) NULL,
	[EligibilityClearingHouse]                     VARCHAR (200) NULL,
	[EligibilityPayerId]                     VARCHAR (200) NULL,
	[ElibilityPlugin]                     VARCHAR (200) NULL,
    PRIMARY KEY CLUSTERED ([InsuranceCarriersID] ASC)
);

go 

drop procedure if exists [cps_all].[ssis_InsuranceCarriers];
go

create procedure [cps_all].[ssis_InsuranceCarriers]
as begin

truncate table [cps_all].[InsuranceCarriers];


;with level1 as (
	select  distinct
		ic.InsuranceCarriersId InsuranceCarriersId, ic.inactive Inactive, ltrim(rtrim(ic.ListName)) InsuranceName,

		g.Name InsuranceGroup, 
		m.Description CarrierType,
		m1.Description FinancialClass,
		m2.Description FilingMethod,
		case when ic.FilingType = 1 then 'paper' when ic.FilingType = 2 then 'electronic' else 'none' end FilingType,
		m3.Description InsurancePolicyType,
		cl2.ClearinghouseName ClaimClearingHouse,
		claim.ClaimPayerId ClaimPayerId,
		plu2.Name ClaimPlugin, 
		cl.ClearinghouseName EligibilityClearingHouse,
		edi.EligibilityPayerId EligibilityPayerId, 
		plu.Name ElibilityPlugin

		--isnull(i.TotalSince2017,0) TotalEligibilityVerifiedSince2017
	from [cpssql].CentricityPS.dbo.InsuranceCarriers ic
		left join [cpssql].CentricityPS.dbo.InsuranceGroup g on ic.InsuranceGroupId = g.InsuranceGroupId
		left join [cpssql].CentricityPS.dbo.MedLists m on ic.CarrierTypeMId = m.MedListsId and m.TableName = 'carriertypes'
		left join [cpssql].CentricityPS.dbo.MedLists m1 on ic.FinancialClassMId = m1.MedListsId and m1.TableName = 'financialclass'
		left join [cpssql].CentricityPS.dbo.MedLists m2 on ic.FilingMethodMId = m2.MedListsId and m2.TableName = 'filingmethods'
		left join [cpssql].CentricityPS.dbo.MedLists m3 on ic.PolicyTypeMId= m3.MedListsId and m3.TableName = 'insurancePolicyTypes'
		left join [cpssql].CentricityPS.dbo.InsuranceCarrierCompany edi on ic.InsuranceCarriersID = edi.InsuranceCarriersID and edi.eligibilityClearingHouseId is not null
		left join [cpssql].CentricityPS.dbo.Plugin plu on plu.PluginId = edi.EligibilityPluginId
		left join [cpssql].CentricityPS.dbo.ClearingHouse cl on cl.ClearingHouseid = edi.eligibilityClearingHouseId
		left join [cpssql].CentricityPS.dbo.InsuranceCarrierCompany claim on ic.InsuranceCarriersID = claim.InsuranceCarriersID and claim.claimClearingHouseId is not null
		left join [cpssql].CentricityPS.dbo.ClearingHouse cl2 on cl2.ClearingHouseid = claim.claimClearingHouseId
		left join [cpssql].CentricityPS.dbo.Plugin plu2 on plu2.PluginId = claim.ClaimPluginId


) --select * from level1
, doh as (
	select 
		InsuranceCarriersId, InsuranceName , 
		case 
			when [InsuranceName] in ('WPS VACAA','Tricare - West Region Claims hnfs','Tricare CHCBP  - South Region',
										'Triwest Healthcare Alliance Choice/VA','Triwest Healthcare Alliance','TriWest WPS VAPC3') 
					then 'VA'
			when InsuranceName in ('AMHD Case Mgr','Diabetes Clinic','Family Planning','OB Global Plan','Quest Pending','Self Pay','Sliding Fee Scale') 
				then 'Uninsured'

			when [InsuranceName] in ('Aarp Medicare Complete MDX Hawaii','AlohaCare Advantage','AlohaCare Advantage Plus','AlohaCare Quest FFS','AMHD MD',
										'Cyrca Shott (Transplant)','Hansen''s Dz only','HMSA Akamai Advantage Plan','HMSA Akamai Advantage Plus','HMSA Basic Health Hawaii',
										'HMSA Quest FFS','Humana','Koan Risk Solutions, Inc.','Medicaid ACS','Medicare NGS','Ohana CCS','Ohana CCS MD','Ohana Health Plan QExA',
										'Ohana Health Plan Quest','Ohana Medicare','Secure Horizons Medicare Direct','United Healthcare Evercare BH','UnitedHealthcare C P  Quest',
										'UnitedHealthcare Evercare','UnitedHealthcare Evercare QExA') 
					then 'Public'
			when [InsuranceName] in ('Hanson Joseph','Jacob-Joshua Ka''aikaula','(kaiser)','Kaiser Foundation','Kaiser Quest','Todays Options') 
				then 'Private'
			when [InsurancePolicyType] = 'Commercial Private Non MC  5' 
				then 'Private'
			when [InsuranceGroup] = 'Commercial' or [FinancialClass] = 'Commercial' 
				then 'Private'
			else 'Not Classified'
		end [Classify_DoH_CVR],

		case 
			when [InsuranceCarriersID] in (88, 98, 24, 165,167,176) then 'Grant' 
			when ltrim(rtrim(InsuranceName)) like 'Ohana%' or ltrim(rtrim(InsuranceName)) = 'Wellcare' then 'Ohana'
			when ltrim(rtrim(InsuranceName)) like 'UnitedHealthcare%' or ltrim(rtrim(InsuranceName)) like 'United Healthcare%' then 'UHC'
			when ltrim(rtrim(InsuranceName)) in ('self pay', 'Quest Pending','Sliding fee Scale') then 'Uninsured'
			when ltrim(rtrim(InsuranceName)) like 'AlohaCare%' then 'AlohaCare'
			when ltrim(rtrim(InsuranceName)) like 'HMSA%' then 'HMSA'
			when InsuranceCarriersID = 3 then 'Medicare'
			when InsuranceCarriersID = 8 then 'Medicaid'
			else 'Other'
		end [Classify_Major_Insurance]
	from level1
)
--select * from doh
, u as (
	select 
		ic.InsuranceCarriersId, ic.InsuranceName , ic.Inactive,

		ic.InsuranceGroup, ic.CarrierType, ic.FinancialClass, ic.FilingMethod, ic.InsurancePolicyType,ic.FilingType,
		ic.ClaimClearingHouse, ic.ClaimPlugin, ic.ClaimPayerId,
		ic.EligibilityClearingHouse, ic.ElibilityPlugin, ic.EligibilityPayerId,

		Classify_Major_Insurance, 
		Classify_DoH_CVR,
		case
			when [Classify_DoH_CVR] = 'Public' and CarrierType = 'Medicaid' then 'Medicaid'
			when [Classify_DoH_CVR] = 'Public' and ic.InsuranceName != 'Ohana CCS' then 'Medicare'
		else 'Not'
		end Classify_Meaningful_Use

	from doh
		left join level1 ic on ic.InsuranceCarriersId = doh.InsuranceCarriersId
) 
--select * from u

insert into cps_all.InsuranceCarriers
	(
		[InsuranceCarriersID],[Inactive],[InsuranceName],
		[InsuranceGroup],[CarrierType],
		[FinancialClass],[FilingMethod],[FilingType],[InsurancePolicyType],
		[ClaimClearingHouse], [ClaimPayerId], [ClaimPlugin],
		[EligibilityClearingHouse], [EligibilityPayerId], [ElibilityPlugin],
		[Classify_Major_Insurance],[Classify_DoH_CVR],[Classify_Meaningful_Use]
	) 
select
		[InsuranceCarriersID],[Inactive],[InsuranceName],
		[InsuranceGroup],[CarrierType],
		[FinancialClass],[FilingMethod],[FilingType],[InsurancePolicyType],
		[ClaimClearingHouse], [ClaimPayerId], [ClaimPlugin],
		[EligibilityClearingHouse], [EligibilityPayerId], [ElibilityPlugin],
		[Classify_Major_Insurance],[Classify_DoH_CVR],[Classify_Meaningful_Use]
from u


drop table if exists #insuranceCount
end
go
