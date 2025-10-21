
USE [CpsWarehouse]
GO
drop proc if exists dbo.ssis_job_cps_hchp;
GO
create procedure dbo.ssis_job_cps_hchp
as begin
	exec CpsWarehouse.cps_hchp.ssis_HCHP_Dashboard
	exec CpsWarehouse.cps_hchp.ssis_HCHP_LastClientStatus
	exec CpsWarehouse.cps_hchp.ssis_HCHP_Patient_Appointments
	exec CpsWarehouse.cps_hchp.ssis_CBCMMetricDueNow
	exec CpsWarehouse.cps_hchp.ssis_CBCM_AcuityScore
	exec CpsWarehouse.cps_hchp.ssis_CBCM_metric
end
go

