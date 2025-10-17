USE [CpsWarehouse]
GO
drop proc if exists dbo.ssis_job_cps_all;
GO
create procedure dbo.ssis_job_cps_all
as begin
	exec CpsWarehouse.[cps_all].[ssis_Location];
	exec CpsWarehouse.[cps_all].[ssis_DoctorFacility];
	exec CpsWarehouse.[cps_all].[ssis_PatientProfile];
	exec CpsWarehouse.[cps_all].[ssis_PatientRace];
	exec CpsWarehouse.[cps_all].[ssis_InsuranceCarriers];
	exec CpsWarehouse.[cps_all].[ssis_PatientInsurance];
end
go
