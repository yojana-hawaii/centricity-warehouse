
USE [CpsWarehouse]
GO
drop proc if exists dbo.ssis_job_cps_bh;
GO
create procedure dbo.ssis_job_cps_bh
as begin
	exec CpsWarehouse.cps_bh.ssis_BH_Patient;
	exec CpsWarehouse.cps_bh.ssis_BH_Metric_All;
	exec CpsWarehouse.cps_bh.ssis_BH_SbirtCodes;
	exec CpsWarehouse.cps_bh.ssis_BH_SbirtObs;
	exec CpsWarehouse.cps_bh.ssis_BH_Phq_Gad;
end
go
