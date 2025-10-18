use CpsWarehouse

go

drop proc if exists cps_cc.rpt_ER_Followup;
go

create proc [cps_cc].[rpt_ER_Followup]
	(
		@StartDate date,
		@EndDate date,
		@ER varchar(100) = NULL,
		@ER_Hospital varchar(100) = NULL,
		@Insurance varchar(100) = null,
		@Facility varchar(50) = NULL,
		@ProviderSeen varchar(10) = NULL

	)
as 
begin

	--declare 
	--	@StartDate date = '2019-02-1', 
	--	@EndDate date = '2019-02-13',  
	--	@ER nvarchar(3) = 'All',
	--	@ER_Hospital nvarchar(5) = 'all',
	--	@Insurance nvarchar(100) = 'all', 
	--	@Facility nvarchar(50) = 'all',
	--	@ProviderSeen nvarchar(10) = '0_7'; 
	


	select
		@ER = case when isNumeric(@ER) = 1 then cast(@ER as smallint) end,
		@ER_Hospital= case when @ER_Hospital = 'All' then null else @ER_Hospital end,
		@Insurance = case when @Insurance = 'All' then null else @Insurance end,
		@Facility = case when @Facility = 'All' then null else @Facility end,
		@ProviderSeen = case when @ProviderSeen = 'All' then null else @ProviderSeen end;

	select * 
	from cps_cc.rpt_view_er_followup
	where DischargeDate >= @StartDate
		and DischargeDate <= @EndDate
		and ER = isnull(@ER, ER)
		and ER_Hosp_Name = isnull(@ER_Hospital , ER_Hosp_Name)
		and PrimaryInsuranceGroup = isnull(@Insurance, PrimaryInsuranceGroup)
		and [Location] = isnull(@Facility , [Location])
		and Actual_Qualified_Appt_Range = isnull(@ProviderSeen, Actual_Qualified_Appt_Range) 
		
end

go

