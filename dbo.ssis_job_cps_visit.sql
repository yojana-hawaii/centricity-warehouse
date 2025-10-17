USE [CpsWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop proc if exists [ssis_job_cps_Visit];
go
create procedure [dbo].[ssis_job_cps_Visit]
as begin

exec CpsWarehouse.[cps_visits].[ssis_Appointments];
exec CpsWarehouse.[cps_visits].[ssis_Document];
exec CpsWarehouse.[cps_visits].[ssis_PatientVisitType];
exec CpsWarehouse.[cps_visits].[ssis_PatientVisitType_Join_Document] 
exec CpsWarehouse.cps_visits.ssis_ApptCycleTime;
end

go
