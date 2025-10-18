USE [CpsWarehouse]
GO
drop proc if exists dbo.ssis_job_cps_hl7;
GO
create procedure dbo.ssis_job_cps_hl7
as begin
	exec CpsWarehouse.cps_hl7.ssis_all_HL7_Mapping;
end
go
