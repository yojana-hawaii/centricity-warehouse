
USE [CpsWarehouse]
GO
drop proc if exists dbo.ssis_job_cps_cc;
GO
create procedure dbo.ssis_job_cps_cc
as begin
	exec CpsWarehouse.cps_cc.ssis_er_followup;
	exec CpsWarehouse.cps_cc.ssis_ER_Count;
	exec CpsWarehouse.cps_cc.ssis_Protocol_Age_Sex;
	exec CpsWarehouse.cps_cc.ssis_Protocol_Diabetes;

	exec CpsWarehouse.cps_cc.ssis_covid_Tracking;
	exec CpsWarehouse.cps_cc.ssis_covid_supplyTracker;
	exec CpsWarehouse.cps_cc.ssis_Covid_Vaccine_Supplier;
	exec CpsWarehouse.cps_cc.ssis_Covid_Wellness_Form;

	exec CpsWarehouse.cps_cc.ssis_CCCKD;
	exec CpsWarehouse.cps_cc.ssis_CCDiabetes;
	exec CpsWarehouse.cps_cc.ssis_cchabbits;
	exec CpsWarehouse.cps_cc.ssis_ccHTN;
	exec CpsWarehouse.cps_cc.ssis_ccSMG;
end
go