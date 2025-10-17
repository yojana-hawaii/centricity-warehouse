
use CpsWarehouse
go
--	


drop table if exists cps_visits.ApptLog;
go
create table cps_visits.ApptLog (
	AppointmentsID			INT				not null,
	[PID]					NUMERIC (19)    NOT NULL,
	[ApptDate]				DATE			NOT NULL,
    [StartTime]				VARCHAR (5)		NOT NULL,
	[Scheduled]				DATE			NOT NULL,
	[LeftMessage]			datetime		null,
	[Confirmed]				datetime		null,
	[Well_Confirmed]		datetime		null,
	[Arrived]				datetime		null,
	[RegistrationComplete]	datetime		null,
	[ReadyForProvider]		datetime		null,
	[CheckedOut]			datetime		null,
	[PhoneIssue]			datetime		null,
	[NoShow]				datetime		null,
	[LeftEarly]				datetime		null,
	[ScheduledVsApptDate(days)]		as		datediff(day, scheduled, apptdate),
	[LeftMessageVsApptDate(days)]	as		datediff(day, [LeftMessage], apptdate),
	[ConfirmedVsApptDate(days)]		as		datediff(day, [Confirmed], apptdate),
	[LeftEarlyVsApptTime(min)]		as		case 
												when datediff(day, cast(apptdate as datetime) + cast(starttime as datetime ) , [LeftEarly]) < 1
												then datediff(minute, cast(apptdate as datetime) + cast(starttime as datetime ) , [LeftEarly])
											end, --check only if less than a day
	[LeftEarlyVsArriveTime(min)]	as		case 
												when datediff(day, [Arrived] , [LeftEarly]) < 1
												then datediff(minute, [Arrived], [LeftEarly])
											end, --check only if less than a day
	[Cancel]				datetime		null,
	[UnknownStatus]			datetime		null,
	
	PRIMARY KEY CLUSTERED ([AppointmentsID] ASC),

);
go

drop proc if exists cps_visits.ssis_ApptLog;
go
create proc cps_visits.ssis_ApptLog
as begin

	-- some recordID / appointmentID is linked to multiple patients --> delete those (21 in 3 years)
	drop table if exists #dups;
	with dups as (
	select 
		distinct patientprofileid, recordid 
	from cpssql.CentricityPS.dbo.ActivityLog acl
	where acl.FunctionName = 'change appointment status' 
		and acl.created > = '2017-01-01'

	)
		select recordid, count(*) tot
		into #dups
		from dups
		group by recordid
		having count(*) > 1;

	with logs as (
		select
			pp.PId PID, RecordId AppointmentsId, 
			ap.ApptDate, ap.StartTime,
			ap.created Scheduled, 
	
			case
				when Value2 in ('Busy Number',  'No Answer', 'No Phone', 'Phone Disconnected','Wrong Phone Number') then 'Phone Issue'

				when value2 in ('Cancel/Facility Error', 'Data Entry Error', 'Deceased', 'Late Cancel','Patient Cancelled Appt','Provider Cancelled Appt')  then 'Cancel'
				when value2 = 'Select a Reason . . .' then 'Unknown Status'
				else value2
			end Value2, 
			acl.LastModified LastModified, 
			case when ap.LastModifiedBy = 'well' then ap.LastModified end [Well_confirmed]
		from cpssql.CentricityPS.dbo.ActivityLog acl
			inner join cps_visits.Appointments ap on acl.RecordId = ap.AppointmentsID
			inner join cps_all.PatientProfile pp on pp.PatientProfileId = acl.PatientProfileId
		where acl.FunctionName = 'change appointment status'
			and acl.recordID not in (select recordid from #dups)
			
	)
	, u as (
		select 
			AppointmentsId, PID, 
			ApptDate, StartTime,Scheduled ,
			[Left Message] LeftMessage,[Confirmed],  [Arrived], [Registration Complete] RegistrationComplete, 
			[Ready for provider] ReadyForProvider, [Checked Out] CheckedOut,
			[Phone Issue] PhoneIssue, [No Show] NoSHow, [Left without being seen] [LeftEarly], 
			[Cancel],[Unknown Status] [UnknownStatus], Well_confirmed
		from(
			select 
				AppointmentsId, PID, 
				ApptDate, StartTime,Scheduled , 
				Value2, LastModified, Well_confirmed
			from logs
		) q
		pivot (
			max(lastModified)
			for Value2 in (
				[Left Message],[Confirmed],  [Arrived], [Registration Complete], [Ready for provider], [Checked Out] ,
				[Phone Issue], [No Show], [Left without being seen], [Cancel],[Unknown Status]
			) 
		)pvt
	)
 insert into cps_visits.ApptLog(
			[AppointmentsID], [PID], [ApptDate], [StartTime], [Scheduled], 
			[LeftMessage], [Confirmed], [Arrived], [RegistrationComplete], 
			[ReadyForProvider], [CheckedOut], [PhoneIssue], [NoShow], 
			[LeftEarly], [Cancel], [UnknownStatus], Well_confirmed
		)
		select
			[AppointmentsID], [PID], [ApptDate], [StartTime], [Scheduled], 
			[LeftMessage], [Confirmed], [Arrived], [RegistrationComplete], 
			[ReadyForProvider], [CheckedOut], [PhoneIssue], [NoShow], 
			[LeftEarly], [Cancel], [UnknownStatus],Well_confirmed
		from u;
end 
go
