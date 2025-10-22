go
use CpsWarehouse
go
drop table if exists cps_obs.LabsFlowsheet;
go
create table cps_obs.LabsFlowsheet(
	PID numeric(19) not null, 
	SDID numeric(19) not null, 
	XID numeric(19) not null, 
	PatientID int not null,
	ObsDate date not null,
	[HGBA1C] varchar(2000) null, 
	[LDL] varchar(2000) null, 
	[Lead_Screening] varchar(2000) null, 
	[Albumin/Creatinine Ratio (ACR)] varchar(2000) null, 
	[Chlamydia] varchar(2000) null, 
	[IFobt] varchar(2000) null, 
	[Colonoscopy] varchar(2000) null, 
	[Mammogram] varchar(2000) null, 
	[Pap Smear] varchar(2000) null, 
	[Fundus in Optometry] varchar(2000) null, 
	[Diab Retinal Exam] varchar(2000) null, 
	[Diab Eye Exam Scanned] varchar(2000) null, 
	[Bone Dexa] varchar(2000) null, 
	[Dexa Left Hip] varchar(2000) null, 
	[Dexa Right Hip] varchar(2000) null, 
	[Dexa Spine] varchar(2000) null, 
	[Random BG] varchar(2000) null, 
	[HPV] varchar(2000) null

)

go
drop proc if exists cps_obs.ssis_LabsFlowsheet;
go
create proc cps_obs.ssis_LabsFlowsheet
as 
begin
	declare @StartDate date = '2019-01-01';
	declare @FlowsheetId numeric(19,0) = 1969702579437570; /*zzLabs*/
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

	)
	insert into cps_obs.LabsFlowsheet(
		PID, SDID, XID, PatientID,ObsDate,[HGBA1C], [LDL], 
		[Lead_Screening] , [Albumin/Creatinine Ratio (ACR)], 
		[Chlamydia], [IFobt], [Colonoscopy], [Mammogram], [Pap Smear], [Fundus in Optometry], 
		[Diab Retinal Exam], [Diab Eye Exam Scanned], [Bone Dexa], [Dexa Left Hip], 
		[Dexa Right Hip], [Dexa Spine], [Random BG], [HPV]
	)
	select
		PID, SDID, XID, PatientID,ObsDate,[HGBA1C], [LDL], 
		[Lead_Screening], [Albumin/Creatinine Ratio (ACR)], 
		[Chlamydia], [IFobt], [Colonoscopy], [Mammogram], [Pap Smear], [Fundus in Optometry], 
		[Diab Retinal Exam], [Diab Eye Exam Scanned], [Bone Dexa], [Dexa Left Hip], 
		[Dexa Right Hip], [Dexa Spine], [Random BG], [HPV]
	from u
end
go
