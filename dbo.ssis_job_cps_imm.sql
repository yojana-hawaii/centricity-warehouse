

USE [CpsWarehouse]
GO
drop proc if exists dbo.ssis_job_cps_imm;
GO
create procedure dbo.ssis_job_cps_imm
as begin
	exec CpsWarehouse.cps_imm.ssis_ImmunizationSetup;
	exec CpsWarehouse.cps_imm.ssis_ImmunizationGiven;
	exec CpsWarehouse.cps_imm.ssis_ImmunizationWithCombo;
	exec CpsWarehouse.cps_imm.ssis_Immunization_Combo;

	--exec CpsWarehouse.cps_imm.ssis_SrxCurrentInventory;
	--exec CpsWarehouse.cps_imm.ssis_SrxDuplicateInventory;
end
go
