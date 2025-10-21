use CpsWarehouse
go

drop proc if exists dbo.ssis_job_cps_opt
go

CREATE procedure [dbo].[ssis_job_cps_opt]
as begin
exec [CpsWarehouse].[cps_opt].[ssis_Contact]
exec [CpsWarehouse].[cps_opt].[ssis_Glasses]
end

go