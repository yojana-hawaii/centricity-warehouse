use CpsWarehouse
go
drop proc if exists dbo.ssis_job_cps_insurance
go
create proc dbo.ssis_job_cps_insurance
as
begin
	exec CpsWarehouse.cps_insurance.ssis_Ohana_Services
	exec CpsWarehouse.cps_insurance.ssis_Ohana_CPT_ICD
	exec CpsWarehouse.cps_insurance.ssis_Ohana_Labs_Referrals
end

go