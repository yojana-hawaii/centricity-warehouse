use CpsWarehouse
go

drop proc if exists dbo.ssis_job_cps_doh
go

CREATE procedure [dbo].ssis_job_cps_doh
as begin
exec [CpsWarehouse].cps_doh.ssis_CVRClient
exec [CpsWarehouse].cps_doh.ssis_CVRCLientObs
exec [CpsWarehouse].cps_doh.ssis_CVRVisitClinicalList
end

go