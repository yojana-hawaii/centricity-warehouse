use CpsWarehouse
go
drop proc if exists [dbo].ssis_job_cps_track;
go
CREATE procedure [dbo].ssis_job_cps_track
as begin
exec [CpsWarehouse].[cps_track].[ssis_papHPVTracking];
exec [CpsWarehouse].[cps_track].[ssis_breastDiagnosis];
end
go