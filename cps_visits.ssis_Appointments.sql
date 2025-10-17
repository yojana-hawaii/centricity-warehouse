
use CpsWarehouse
go
drop table if exists cps_visits.[Appointments];
go
CREATE TABLE cps_visits.[Appointments] (
    [AppointmentsID]   INT            NOT NULL	primary key,
    [Facility]		   varchar(100)    NOT NULL,
	[FacilityID]	   int				NOT NULL,
    [PID]              NUMERIC (19)   NOT NULL,
    [ListName]         NVARCHAR (160) NOT NULL,
    [PVID]             NUMERIC (19)   NULL,
    [DoctorFacilityID] INT            NOT NULL,
    [ApptDate]         DATE           NOT NULL,
    [StartTime]        VARCHAR (5)    NOT NULL,
    [EndTime]          VARCHAR (5)    NOT NULL,
    [Duration]         SMALLINT       NOT NULL,
	[ApptStatus]       VARCHAR (50)   NULL,
    [Canceled]         BIT            NOT NULL,
    [PatientVisitID]   INT            NULL,
    [ApptType]         VARCHAR (50)   NULL,
    [InternalReferral] NVARCHAR (15)  NULL,
	[ApptNotes]        VARCHAR (255)  NULL,
    [ApptSetID]        INT            NULL,
    [casesID]          INT            NULL,
    [ReferralSource]   VARCHAR (50)   NULL,
    [created]          DATE           NOT NULL,
    [CreatedBy]        VARCHAR (50)   NOT NULL,
    [LastModified]     DATE           NOT NULL,
    [LastModifiedBy]   VARCHAR (50)   NOT NULL,
	--[DocCreated]	   tinyint		  not null /*not used, docCreated and DocId => SDID*/
);

go

drop proc if exists cps_visits.[ssis_Appointments];
go
CREATE PROCEDURE cps_visits.[ssis_Appointments]
as 
begin

	truncate table cps_visits.[Appointments] ;

	declare @apptDate datetime = '2017-01-01';
	drop table if exists #appt;
	select 
		app.AppointmentsId AppointmentsId, 
		fac.Facility,
		fac.FacilityID,
		pp.pid PID, 

		df.ListName,
		df.PVID,
		case when app.DoctorId =  app.ResourceId then app.DoctorId
			when app.ResourceId is null then app.DoctorId
			else app.ResourceId end DoctorFacilityID,

		convert(date, app.apptstart) ApptDate, 
		convert(varchar(5), app.apptstart, 108) StartTime, 
		convert(varchar(5), app.apptstop, 108) EndTime, 
		isnull(app.Duration, datediff(mi, app.apptstart, app.apptstop) ) Duration,

		app.Status ApptStatus, 
		isnull(app.Canceled,0) Canceled, 

		app.PatientVisitId PatientVisitId,
		app.ApptTypeId,
		apt2.Name ApptType,
		apt.InternalReferral,

		convert(varchar(255),app.Notes) ApptNotes,
		app.ApptSetId ApptSetId, 
		app.CasesId CasesId,
		ref.Description ReferralSource, 
		convert(date,app.Created) Created, app.CreatedBy CreatedBy, 
		convert(date,app.LastModified) LastModified, app.LastModifiedBy LastModifiedBy
	into #appt
	from [cpssql].CentricityPS.dbo.Appointments app
		left join [cpssql].CentricityPS.dbo.MedLists ref on ref.MedListsId = app.ReferralSourceMId
		inner join [cpssql].CentricityPS.dbo.[PatientProfile] pp on pp.patientProfileID = app.ownerid
		left join [cpssql].CentricityPS.dbo.ApptType apt2 on apt2.ApptTypeId = app.ApptTypeId
		left join cps_all.[Location] fac on fac.FacilityID = app.FacilityID and fac.MainFacility = 1
		left join cps_visits.tmp_view_apptType apt on apt.AppointmentsID = app.AppointmentsID
		left join cps_all.[DoctorFacility] df on df.doctorfacilityid = case when app.DoctorId =  app.ResourceId then app.DoctorId
																			when app.ResourceId is null then app.DoctorId
																			else app.ResourceId end
	where ApptKind = 1 
		and app.ApptStart >= @apptDate

		--EXEC tempdb..sp_help '#appt';
	--select * from u
	--where AppointmentsId = 1251806
insert into cps_visits.Appointments (
		AppointmentsId, Facility, [FacilityID], PID, ApptDate, StartTime, EndTime, Duration, ApptStatus, Canceled, ApptNotes, DoctorFacilityID, 
		PVID,Listname, PatientVisitID, ApptType,[InternalReferral], ApptSetID, CasesID, ReferralSource, Created, CreatedBy, 
		LastModified, LastModifiedBy
	) 
select 
	AppointmentsId, Facility, [FacilityID], PID, ApptDate, StartTime, EndTime, Duration, ApptStatus, Canceled, ApptNotes, DoctorFacilityID, 
	PVID,Listname, PatientVisitID, ApptType,[InternalReferral], ApptSetID, CasesID, ReferralSource, Created, CreatedBy, 
	LastModified, LastModifiedBy
from #appt;

end

go
