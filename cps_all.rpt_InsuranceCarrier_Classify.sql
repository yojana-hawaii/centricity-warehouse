use CpsWarehouse
go
drop proc if exists [cps_all].[rpt_InsuranceCarrier_Classify] 
go
create PROCEDURE [cps_all].[rpt_InsuranceCarrier_Classify] 
	(
		@DoH nvarchar(20) = null,
		@Insurance nvarchar(20) = null,
		@Inactive nvarchar(3) = null,
		@MeaningfulUse nvarchar(20) = null,
		@FilingMethod nvarchar(20) = null,
		@FilingType nvarchar(20) = null
	)
AS BEGIN
--declare 
--	@DoH nvarchar(20) = 'All',
--	@Insurance nvarchar(20) = 'All',
--	@Inactive nvarchar(3) = '0',
--	@MeaningfulUse nvarchar(20) = 'all',
--	@FilingMethod nvarchar(20) = 'hcfa',
--	@FilingType nvarchar(20) = 'electronic'

select 
	@DoH = case when @DoH = 'All' then null else @DoH end,
	@Insurance = case when @Insurance = 'All' then null else @Insurance end,
	@MeaningfulUse = case when @MeaningfulUse = 'All' then null else @MeaningfulUse end,
	@FilingMethod = case when @FilingMethod = 'All' then null else @FilingMethod end,
	@FilingType = case when @FilingType = 'All' then null else @FilingType end

declare	
	@Inactive1 bit = case when @Inactive = 'All' then null else @Inactive end
	
--select @DoH, @Inactive1, @Insurance, @MeaningfulUse, @FilingMethod,@FilingType

select * 
from cps_all.InsuranceCarriers
where 
	Classify_DoH_CVR = isnull(@DoH, Classify_DoH_CVR)
	and Classify_Major_Insurance = isnull(@Insurance, Classify_Major_Insurance)
	and Inactive = isnull(@Inactive1, Inactive)
	and Classify_Meaningful_Use = isnull(@MeaningfulUse, Classify_Meaningful_Use)
	and FilingType = isnull(@FilingType, FilingType)
	and FilingMethod = isnull(@FilingMethod, FilingMethod)

end
go