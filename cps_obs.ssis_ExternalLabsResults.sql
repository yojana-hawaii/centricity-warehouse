
use CpsWarehouse
go

drop table if exists cps_obs.ExternalLabResults;
create table cps_obs.ExternalLabResults (
	Coding_System varchar(100) not null,
	LabDescription varchar(200) not null,
	LabCode varchar(40) not null,
	HDID int not null,
	ObsTerm varchar(50) not null,
	PID numeric(19,0) not null,
	SDID numeric(19,0) not null,
	LabOrderDate date not null,
	LabReceivedDate datetime2 not null,
	ObsValue varchar(2000) not null,
	PubUser numeric(19,0) not null,
	ListName varchar(160) null,
	LabOrderPanelId numeric(19,0) null,
	LabPanelName varchar(200) null,
	LabPanelCode varchar(200) null,
	LabPanelRequestDate date null
);

go

drop proc if exists cps_obs.ssis_ExternalLabResults;
go
create proc cps_obs.ssis_ExternalLabResults
as
begin
	truncate table cps_obs.ExternalLabResults;

	declare @today date = convert(date, getdate() );
	declare @5years date = dateadd(year, -5, @today);
	declare @YearStart date = datefromparts(year(@5years),1 ,1);



	;with ext_labs as (
		select distinct Coding_System, hdid, ObsTerm, Ext_Result_Description LabDescription, Ext_Result_Code LabCode
		from cps_hl7.all_HL7_Mapping 
		where Coding_System in ('HDRS','CLH','DLS-HPL')
			and hdid != -1
	)
	, u as (
		select 
			ex.Coding_System, LabDescription, LabCode, ex.HDID, ex.ObsTerm, 
			obs.PID PID, obs.sdid SDID, 
			convert(date,obs.obsdate) LabOrderDate, 
			obs.db_updated_date LabReceivedDate,
			obs.obsvalue ObsValue,
			obs.pubuser PubUser, df.ListName, 
			obs.LabOrderPanelId LabOrderPanelId, 
			l.Name LabPanelName, l.Code LabPanelCode, convert(date, l.OrderRequestedDate) LabPanelRequestDate
		from ext_labs ex
			left join cpssql.CentricityPS.dbo.Obs on obs.hdid = ex.HDID 
			left join cps_all.DoctorFacility df on df.PVID = obs.pubuser
			left join cpssql.centricityps.dbo.laborderpanel l on l.laborderpanelid = obs.laborderpanelid
		where 
			obs.xid = 1000000000000000000 /*active row*/
			and usrid = -3 /*link logic*/
			and change not in (10,11,12) /*file in error*/
			and obs.ObsDate >= @YearStart
			--change = 6 /*unsigned*/ 2/*signed*/
	)
	--	select top 100 * from #LabResults
	insert into cps_obs.ExternalLabResults(
		[Coding_System], [LabDescription], [LabCode],[HDID],[ObsTerm],[PID],[SDID],[LabOrderDate],[LabReceivedDate],[ObsValue],[PubUser],
		[ListName],[LabOrderPanelId],[LabPanelName],[LabPanelCode],[LabPanelRequestDate]
	)
	select 
		[Coding_System], [LabDescription], [LabCode],[HDID],[ObsTerm],[PID],[SDID],[LabOrderDate],[LabReceivedDate],[ObsValue],[PubUser],
		[ListName],[LabOrderPanelId],[LabPanelName],[LabPanelCode],[LabPanelRequestDate]
	from u
end
go
