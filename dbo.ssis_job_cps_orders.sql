use  CpsWarehouse
go
drop proc if exists dbo.ssis_job_cps_orders
go
create procedure dbo.ssis_job_cps_orders
as begin
	exec [CpsWarehouse].[cps_orders].[ssis_OrderCodesAndCategories]
	exec [CpsWarehouse].[cps_orders].[ssis_OrderSpecialist];
	exec [CpsWarehouse].[cps_orders].[ssis_Fact_all_orders];
	exec CpsWarehouse.cps_orders.ssis_email_future_orders;
	/*includes 4 tables - cps_orders.ReferralSetup, cps_orders.ReferralFollowup, cps_orders.ReferralScanned,ps_orders.ReferralFollowup_ByStaff */
	exec CpsWarehouse.[cps_orders].[ssis_referral_Setup_followup_scan]; 

	--exec [CpsWarehouse].[cps_orders].[ssis_EnablingCodes];
	--exec [CpsWarehouse].cps_orders.ssis_BHSbirtCodes

--exec [CpsWarehouse].[cps_orders].[ssis_ApprovedReferral_Specialist_Insurance];

--referral sepcialist breakdown
--referral to BH
--internal referral
--referral setup specialist
--referral followup
--referal status by providers
end

go