use CpsWarehouse
go

drop proc if exists [dbo].[ssis_job_cps_setup];
go
create procedure [dbo].[ssis_job_cps_setup]
as begin
exec CpsWarehouse.cps_setup.[ssis_Encounters_DocumentTemplates]
exec CpsWarehouse.[cps_setup].[ssis_Form_Components] 
exec CpsWarehouse.[cps_setup].[ssis_Text_Components] 
end

go