go

use CpsWarehouse
go

drop table if exists cps_obs.VitalSignFlowsheet;
go
create table cps_obs.VitalSignFlowsheet(
	PID numeric(19) not null, 
	SDID numeric(19) not null, 
	XID numeric(19) not null, 
	PatientID int not null,
	ObsDate date not null,
	[Height_Inches] varchar(2000) null, 
	[Weight_lbs] varchar(2000) null, 
	[BSA] varchar(2000) null, 
	[BMI] varchar(2000) null, 
	[Temperature_F] varchar(2000) null, 
	[Temperature_Site] varchar(2000) null, 
	[Pulse_Rate] varchar(2000) null, 
	[Pulse_Rythm] varchar(2000) null, 
	[Respitration_Rate] varchar(2000) null, 
	[BP_Systolic] varchar(2000) null, 
	[BP_Diastolic] varchar(2000) null, 
	[Smoking_Status] varchar(2000) null,
	[Chief_Complaint] varchar(2000) null,

	[Dietary_Counseling] varchar(2000) null,
	[Exercise_Counseling] varchar(2000) null,
	[IQ_Diet] varchar(2000) null,
	[IQ_Physical_Activity] varchar(2000) null,

	[MCHAT] varchar(2000) null,
	[Peds_Q] varchar(2000) null,
	
	[Domestic_Abuse] varchar(2000) null,

	[SDOH_Housing] varchar(2000) null,
	[SDOH_Food] varchar(2000) null,
	[SDOH_Financial] varchar(2000) null,
	[SDOH_Transport] varchar(2000) null,
	



)

go
drop proc if exists cps_obs.ssis_VitalSignFlowsheet;
go

create proc cps_obs.ssis_VitalSignFlowsheet
as
begin
	declare @StartDate date = '2022-01-01';
	declare @FlowsheetId numeric(19,0) = 1541165416200550; /*Vital Sign. One in primary care*/
	--function to create dynamic pivot sql
	declare @pivoted_sql nvarchar(max) = fxn.ConvertFlowsheetIntoDynamicPivot( @FlowsheetId, @StartDate)
	--print @pivoted_sql
	exec sp_executesql @pivoted_sql

	drop table if exists #pivot_table;
	select * 
	into #pivot_table
	from  ##dynamic_temp_table

	drop table if exists ##dynamic_temp_table;

	;with u as (
		select  pvt.* 
		from #pivot_table pvt

	) --select top 10 * from u
	INSERT INTO cps_obs.VitalSignFlowsheet(
		PID, SDID, XID, PatientID,ObsDate,
		[Height_Inches], [Weight_lbs], [BSA], [BMI], 
		[Temperature_F], [Temperature_Site], [Pulse_Rate], 
		[Pulse_Rythm], [Respitration_Rate], 
		[BP_Systolic], [BP_Diastolic], [Smoking_Status],[Chief_Complaint],
		[Dietary_Counseling], [Exercise_Counseling], [IQ_Diet], [IQ_Physical_Activity],[MCHAT],[Peds_Q],[Domestic_Abuse],
		[SDOH_Housing],[SDOH_Food],[SDOH_Financial],[SDOH_Transport]
	)
	select 
		PID, SDID, XID, PatientID,ObsDate,
		[Height_Inches], [Weight_lbs], [BSA], [BMI], 
		[Temperature_F], [Temperature_Site], [Pulse_Rate], 
		[Pulse_Rythm], [Respitration_Rate], 
		[BP_Systolic], [BP_Diastolic], [Smoking_Status],[Chief_Complaint],
		[Dietary_Counseling], [Exercise_Counseling], [IQ_Diet], [IQ_Physical_Activity],[MCHAT],[Peds_Q],[Domestic_Abuse],
		[SDOH_Housing],[SDOH_Food],[SDOH_Financial],[SDOH_Transport]
	from u

END

go
