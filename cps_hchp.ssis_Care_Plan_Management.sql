
USE [CpsWarehouse]
GO

drop table if exists [CpsWarehouse].[cps_hchp].[Care_Plan_Management];
go
CREATE TABLE [cps_hchp].[Care_Plan_Management]
(
	CarePlanID numeric(19,0) not null primary key,
	CarePlanGroupID numeric(19,0) not null,
	PID numeric(19,0) not null,
	SDID numeric(19,0) not null,
	SignedDate date not null,
	Goal nvarchar(max) null,
	Instructions nvarchar(max) null,
	Target nvarchar(max) null,
	GoalSetDate date not null,
	GoalMetDate date null
)
go


drop PROCEDURE if exists [cps_hchp].[ssis_Care_Plan_Management] 
go
create procedure [cps_hchp].[ssis_Care_Plan_Management]
as begin

truncate table [cps_hchp].[Care_Plan_Management];

;with u as (
	select 
		c.CarePlanID, c.CarePlanGroupId, c.PID, c.SDID,
		convert(date,c.SignedDate) SignedDate, 
		ltrim(rtrim(c.Goal)) Goal, ltrim(rtrim(c.Instructions)) Instructions, ltrim(rtrim(c.Target)) Target,  
		convert(date,c.GoalSetDate) GoalSetDate, convert(date,c.GoalMetDate) GoalMetDate
	from cpssql.CentricityPS.dbo.CarePlan c
		left join cps_all.PatientProfile pp on pp.pid = c.pid	
	where c.FiledInError = 'N'
		and c.SignedByPVID is not null
		and pp.TestPatient = 0
)

		insert into [cps_hchp].[Care_Plan_Management] (CarePlanID,CarePlanGroupID,PID,SDID,SignedDate,Goal,Instructions,Target,GoalSetDate,GoalMetDate)
		select CarePlanID,CarePlanGroupID,PID,SDID,SignedDate,Goal,Instructions,Target,GoalSetDate,GoalMetDate from u

	end

go
