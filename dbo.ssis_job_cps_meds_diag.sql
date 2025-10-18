
USE [CpsWarehouse]
GO
drop proc if exists dbo.ssis_job_cps_meds_diag;
GO
create procedure dbo.ssis_job_cps_meds_diag
as begin
	exec CpsWarehouse.cps_meds.ssis_PatientMedication;
	exec CpsWarehouse.cps_diag.ssis_Problem_First_Last_Assessment;
end
go
