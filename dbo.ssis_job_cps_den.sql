use CpsWarehouse
go
drop proc if exists dbo.ssis_job_cps_den;
go
create proc ssis_job_cps_den
as
begin
	exec CpsWarehouse.cps_den.ssis_DentalPatientProfile;
	exec CpsWarehouse.cps_den.ssis_slidingFee_Cyrca
	exec CpsWarehouse.cps_den.ssis_Den_CPS_PatientMatching_Algorithm
end 
go