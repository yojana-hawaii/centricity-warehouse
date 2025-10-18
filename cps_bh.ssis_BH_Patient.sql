go
USE [CpsWarehouse]
GO

drop table if exists [CpsWarehouse].cps_bh.BH_Patient;
go
CREATE TABLE [cps_bh].[BH_Patient](
	[PID] [numeric](19, 0) NOT NULL,
	[Psych] [nvarchar](30) null,
	[Therapist] [nvarchar](40) null,

	[LastScheduledProvider] nvarchar(160) not null,
	[LastScheduledLoC] [nvarchar](20) NOT NULL,
	[LastScheduledAppt] [date] NOT NULL,
	[LastScheduledRegistrationStatus] [varchar](30) NOT NULL,
	[LastScheduledCanceled] int NOT NULL,
	[ConsecApptStatus] int NULL,
	
	[FirstSeenProvider] nvarchar(160) null,
	[FirstSeenLoC] [nvarchar](20) NULL,
	[FirstSeenAppt] [date] NULL,

	FirstScheduledProvider nvarchar(160) null,
	FirstScheduledLoC [nvarchar](20) null,
	FirstScheduledAppt [date] null,
	FirstScheduledCancel int null,

	[LastSeenProvider] nvarchar(160) null,
	[LastSeenLoC] [nvarchar](20) NULL,
	[LastseenAppt] [date] NULL,

	[NextProvider] nvarchar(100) null,
	[NextLoC] [nvarchar](20) NULL,
	[NextAppt] [date] NULL,

	[TotalPastAppt] int NOT NULL,
	[TotalCanceled] int NOT NULL,
	[TotalNotCanceled] int NOT NULL,
	[TotalFutureAppt] int NOT NULL

PRIMARY KEY CLUSTERED 
(
	[PID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

drop PROCEDURE if exists [cps_bh].[ssis_BH_Patient] 

go
CREATE procedure [cps_bh].[ssis_BH_Patient]
as begin

truncate table cps_bh.[BH_Patient];

drop table if exists #allBHApptsEver
drop table if exists #lastVisitOfEachPatient
drop table if exists #first_visit_each_patient
drop table if exists #first_appt_each_patient
drop table if exists #visitCountOfEachPaient
drop table if exists #totalCancellations
drop table if exists #ConsecutiveStatusGapAndIslandProblem
drop table if exists #DaysSinceLastVisit



select 
	ApptNumDesc = ROW_NUMBER() OVER (PARTITION BY PID  ORDER BY ApptDate DESC ),
	ApptNumAsc = ROW_NUMBER() OVER (PARTITION BY PID  ORDER BY ApptDate ASC ),
	*
into #allBHApptsEver
from
	(
		select *
		from [cps_bh].[tmp_view_BH_Appointments]
	) x
/*******************
select distinct PID from #allBHApptsEver where pid = 1857289255061460 order by apptdate
select * from #allBHApptsEver order by PID, ApptNumAsc

get last appt of patient
**********************/
SELECT  
	t1.PID,t1.[Provider] LastProvider, t1.Facility LastLoC,
	CONVERT(DATE,t1.ApptDate) LastAppt, t1.RegistrationStatus LastRegistrationStatus,
	t1.Canceled LastCanceled
into #lastVisitOfEachPatient
FROM #allBHApptsEver t1
WHERE t1.ApptNumDesc = 1 
/*******************
select * from #allBHApptsEver
select * from #lastVisitOfEachPatient

get first complete appt
**********************/
;with u as (
	SELECT  min(t1.ApptNumAsc) ApptNumAsc, t1.PID
	FROM #allBHApptsEver t1
	WHERE  Canceled = 0
	group by t1.PID
)
	select bh.PID, bh.[Provider] FirstProvider, bh.Facility FirstLoC, bh.ApptDate FirstAppt
	into #first_visit_each_patient
	from u 
		left join #allBHApptsEver bh on u.PID = bh.PID and u.ApptNumAsc = bh.ApptNumAsc
/*******************
select * from #allBHApptsEver
select * from #lastVisitOfEachPatient
select * from #first_visit_each_patient

first scheduled appt
**********************/
;with u as (
	SELECT  min(t1.ApptNumAsc) ApptNumAsc, t1.PID
	FROM #allBHApptsEver t1
	group by t1.PID
)
	select bh.PID, bh.[Provider] FirstProvider, bh.Facility FirstLoC, bh.ApptDate FirstAppt, bh.Canceled
	into #first_appt_each_patient
	from u 
		left join #allBHApptsEver bh on u.PID = bh.PID and u.ApptNumAsc = bh.ApptNumAsc
/*******************
select * from #allBHApptsEver
select * from #lastVisitOfEachPatient
select * from #first_visit_each_patient
select * from #first_appt_each_patient

total Visit, Total Cancelled
**********************/
SELECT t1.PID, count(*) TotalPastAppt
into #visitCountOfEachPaient
FROM #allBHApptsEver t1
GROUP BY t1.PID

SELECT t1.PID, count(*) TotalCancelled
into #totalCancellations
FROM #allBHApptsEver t1
WHERE t1.Canceled = 1
GROUP BY t1.PID

/*******************
select * from #allBHApptsEver
select * from #lastVisitOfEachPatient
select * from #first_visit_each_patient
select * from #visitCountOfEachPaient
select * from #totalCancellations

consecutive cacellations - this is "gaps and island" problem
**********************/
;with groupByCancelAndNotCancel AS (
	SELECT 
		conscutiveStatus = ROW_NUMBER() OVER (PARTITION BY t1.PID,t1.Canceled ORDER BY t1.apptDate DESC)
		,t1.PID,t1.Canceled,t1.ApptNumDesc
	FROM #allBHApptsEver t1
), totalConsecutive AS (
	SELECT PID, COUNT(*) TotalConsecutive, Canceled
	FROM groupByCancelAndNotCancel
	where conscutiveStatus = ApptNumDesc
	GROUP BY PID,Canceled
) --select * from totalConsecutive 
	SELECT q.PID, 
		q.Canceled, q.TotalConsecutive,
		case when q.Canceled = 1 then q.TotalConsecutive * -1
		else q.TotalConsecutive
		end ConsecApptStatus
	into #ConsecutiveStatusGapAndIslandProblem
	FROM totalConsecutive q

/*******************
select * from #allBHApptsEver
select * from #lastVisitOfEachPatient
select * from #first_visit_each_patient
select * from #visitCountOfEachPaient
select * from #totalCancellations
select * from #ConsecutiveStatusGapAndIslandProblem

last not cancelled appt
**********************/
;with notCancelledAppt as (
	select 
		t1.pid,t1.apptdate, t1.Facility LastSeenLoC, 
		LastNum = ROW_NUMBER() OVER (PARTITION BY t1.PId ORDER BY t1.apptdate DESC),
		t1.[Provider] LastSeenProvider
	from #allBHApptsEver t1
	where t1.Canceled != 1 OR t1.Canceled IS NULL
)
	SELECT r.pid, CONVERT(DATE,r.apptdate) LastSeenAppt, LastSeenProvider, LastSeenLoC
	into #DaysSinceLastVisit
	FROM notCancelledAppt r
	WHERE r.LastNum = 1


/*******************
select * from #allBHApptsEver 
select * from #lastVisitOfEachPatient 
select * from #first_visit_each_patient
select * from #visitCountOfEachPaient
select * from #totalCancellations
select * from #ConsecutiveStatusGapAndIslandProblem
select * from #DaysSinceLastVisit

future appt
**********************/


; with FutureAppts as (
SELECT 
	t2.pid,
	app.apptdate,app.DoctorFacilityID, app.Facility NextLoC, 
	FutureNum = ROW_NUMBER() OVER (PARTITION BY  t2.PID ORDER BY app.apptdate)
FROM #lastVisitOfEachPatient t2
	inner JOIN [CpsWarehouse].[cps_visits].Appointments app ON t2.pid = app.pid
	inner JOIN [CpsWarehouse].[cps_all].DoctorFacility df ON app.DoctorFacilityID = df.DoctorFacilityID
WHERE app.ApptDate >= CONVERT(DATE,GETDATE())
	AND df.JobTitle in ('Therapist','Psychiatrist','Psychologist') 
), NextApptDate as (
SELECT t6.PID,t6.ApptDate NextAppt, df.ListName NextProvider, NextLoC
FROM FutureAppts t6
	inner JOIN [CpsWarehouse].[cps_all].DoctorFacility df ON t6.DoctorFacilityID = df.DoctorFacilityId
WHERE t6.FutureNum = 1
), TotalFutureAppts as  (
SELECT t6.PID, COUNT(*) FutureScheduledAppt
FROM FutureAppts t6
GROUP BY t6.PID
)

, u as (
SELECT 
	t2.pid PID,
	isnull(pp.Psych,'') Psych, 
	isnull(pp.Therapist,'') Therapist, 
	
	t10.FirstProvider, t10.FirstLoC, t10.FirstAppt, 
	t11.FirstProvider FirstScheduledProvider, t11.FirstLoC FirstScheduledLoC, t11.FirstAppt FirstScheduledAppt,t11.Canceled FirstScheduledCancel,

	t2.LastProvider,t2.LastLoC LastLoC,t2.LastAppt,
	t2.LastRegistrationStatus,
	t2.LastCanceled,
	--t5.ConsecApptStatus, 

	t9.LastSeenProvider, t9.LastSeenAppt, t9.LastSeenLoC,
	t7.NextProvider, t7.NextAppt, t7.NextLoC,

	t3.TotalPastAppt,
	ISNULL(t4.TotalCancelled,0) TotalCanceled,
	t3.TotalPastAppt - ISNULL(t4.TotalCancelled,0) TotalNotCanceled,
	isnull(t8.FutureScheduledAppt,0) TotalFutureAppt

FROM #lastVisitOfEachPatient t2
	LEFT JOIN #visitCountOfEachPaient t3 on t2.PID = t3.PID
	LEFT JOIN #totalCancellations t4 on t2.PID = t4.PID
	--LEFT JOIN #ConsecutiveStatusGapAndIslandProblem t5 ON t2.PID = t5.PID
	LEFT JOIN NextApptDate t7 ON t2.PID = t7.PID
	LEFT JOIN TotalFutureAppts t8 ON t2.PID = t8.PID
	LEFT JOIN #DaysSinceLastVisit t9 ON t2.PID = t9.PID
	left join cps_all.PatientProfile pp on pp.pid = t2.PID
	left join #first_visit_each_patient t10 on t10.PID = t2.PID
	left join #first_appt_each_patient t11 on t11.pid = t2.pid
)
--select *  from u
--exec tempdb.dbo.sp_help N'#temp'

insert into cps_bh.[BH_Patient] ([PID],[Psych],[Therapist],[LastScheduledProvider],[LastScheduledLoC],[LastScheduledAppt],
	[LastScheduledRegistrationStatus],[LastScheduledCanceled]/*,[ConsecApptStatus]*/,[FirstSeenProvider],[FirstSeenLoC],
	[FirstSeenAppt],[LastSeenProvider],[LastSeenLoC],[LastseenAppt],[NextProvider],[NextLoC],
	[NextAppt],[TotalPastAppt],[TotalCanceled],[TotalNotCanceled],[TotalFutureAppt],
	FirstScheduledProvider,FirstScheduledLoC,FirstScheduledAppt,FirstScheduledCancel)
select [PID],[Psych],[Therapist],[LastProvider],[LastLoC],[LastAppt],
	[LastRegistrationStatus],[LastCanceled]/*,[ConsecApptStatus]*/,[FirstProvider],[FirstLoC],
	[FirstAppt],[LastSeenProvider],[LastSeenLoC],[LastseenAppt],[NextProvider],[NextLoC],
	[NextAppt],[TotalPastAppt],[TotalCanceled],[TotalNotCanceled],[TotalFutureAppt],
	FirstScheduledProvider,FirstScheduledLoC,FirstScheduledAppt,FirstScheduledCancel
from u;

END
go
