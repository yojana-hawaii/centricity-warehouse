
use CpsWarehouse
go
drop proc if exists dbo.ssis_job_cps_obs;
go
create procedure dbo.ssis_job_cps_obs
as begin
exec CpsWarehouse.cps_obs.ssis_ObsHead
exec CpsWarehouse.cps_obs.ssis_Flowsheet_Recussive
exec CpsWarehouse.cps_obs.ssis_Aapcho
exec CpsWarehouse.cps_obs.ssis_Age_Sex_Protocol_obs
exec CpsWarehouse.cps_obs.ssis_Diabetes_Obs
exec CpsWarehouse.cps_obs.ssis_DirectMessaging_Sent
exec CpsWarehouse.cps_obs.ssis_ExternalLabResults
exec CpsWarehouse.cps_obs.ssis_LabsFlowsheet
exec CpsWarehouse.cps_obs.ssis_VitalSignFlowsheet
end 
go