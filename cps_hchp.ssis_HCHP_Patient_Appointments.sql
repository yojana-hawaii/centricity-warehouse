go
USE [CpsWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop table if exists [CpsWarehouse].cps_hchp.HCHP_Patient_Appointments;
go

CREATE TABLE [cps_hchp].[HCHP_Patient_Appointments](
	[PID] [numeric](19, 0) NOT NULL,

	[LastProvider] nvarchar(160) null,
	[LastLoC] [nvarchar](20)  NULL,
	[LastAppt] [date] NULL,
	[LastRegistrationStatus] [varchar](30)  NULL,
	[LastCanceled] int  NULL,
	[ConsecApptStatus] int NULL,
	
	[FirstProvider] nvarchar(160) null,
	[FirstLoC] [nvarchar](20) NULL,
	[FirstAppt] [date] NULL,

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



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
drop PROCEDURE if exists [cps_hchp].[ssis_HCHP_Patient_Appointments] 
go
CREATE procedure [cps_hchp].[ssis_HCHP_Patient_Appointments]
as begin

truncate table [cps_hchp].[HCHP_Patient_Appointments];

drop table if exists #allBHApptsEver
drop table if exists #lastVisitOfEachPatient
drop table if exists #first_visit_each_patient
drop table if exists #visitCountOfEachPaient
drop table if exists #totalCancellations
drop table if exists #ConsecutiveStatusGapAndIslandProblem
drop table if exists #DaysSinceLastVisit


/*All CBCM data - 
acuity score, 462650
encounter type (face to face, collateral, telephone)  298426
visit type (amhd,ccs,enabling and dischange) 66473
hdid = 489709 and obsvalue = 'CBCM
*/


/*********
find hchp patient and identify cbcm among them
any one with appt with

select * from cps_hchp.tmp_view_HCHPClients 

find all HCHP Appt
*******************/
drop table if exists #allHCHPApptsEver;
select 
	ApptNum = ROW_NUMBER() OVER (PARTITION BY PID  ORDER BY ApptDate DESC ),
	FirstApptNum = ROW_NUMBER() OVER (PARTITION BY PID  ORDER BY ApptDate ASC ),
	*
into #allHCHPApptsEver
from
	(
	SELECT 	distinct 		
		pp.pid, app.ApptDate,app.ApptStatus AS RegistrationStatus,app.Canceled, app.ListName [Provider],
		loc.Facility, app.AppointmentsID
	FROM cps_hchp.tmp_view_HCHPClients h
		LEFT join [CpsWarehouse].[cps_visits].Appointments app on 
								app.pid  = h.PID
								and app.InternalReferral in ('HCHP')
								AND app.ApptDate < CONVERT(DATE,GETDATE() )
								and ApptStatus not in ('Data Entry Error','Cancel/Facility Error')
		left JOIN [CpsWarehouse].[cps_all].PatientProfile pp ON h.PID = pp.pid 
		left join [CpsWarehouse].[cps_all].[Location] loc on loc.FacilityID = app.FacilityID
	) x 

/***************
select * from cps_hchp.tmp_view_HCHPClients
select * from #allHCHPApptsEver		where cbcm = 1

get last appt of patient
**********************/
drop table if exists #lastVisitOfEachPatient
SELECT  
	t1.PID,t1.[Provider] LastProvider, t1.Facility LastLoC,
	CONVERT(DATE,t1.ApptDate) LastAppt, t1.RegistrationStatus LastRegistrationStatus,
	t1.Canceled LastCanceled
into #lastVisitOfEachPatient
FROM #allHCHPApptsEver t1
WHERE t1.ApptNum = 1 

/***************
select * from cps_hchp.tmp_view_HCHPClients
select * from #allHCHPApptsEver		
select * from #lastVisitOfEachPatient

need to add cbcm bit

get first appt
**********************/
drop table if exists #first_visit_each_patient;
;with u as (
	SELECT  min(t1.FirstApptNum) FirstApptNum, t1.PID
	FROM #allHCHPApptsEver t1
	WHERE  Canceled = 0
	group by t1.PID
)
	select bh.PID, bh.[Provider] FirstProvider, bh.Facility FirstLoC, bh.ApptDate FirstAppt
	into #first_visit_each_patient
	from cps_hchp.tmp_view_HCHPClients h
		left join u on u.PID = h.PID
		left join #allHCHPApptsEver bh on u.PID = bh.PID and u.FirstApptNum = bh.FirstApptNum

/***************
select * from cps_hchp.tmp_view_HCHPClients							967
select * from #allHCHPApptsEver						
select * from #lastVisitOfEachPatient				967
select * from #first_visit_each_patient				967

need to add cbcm bit

total Visit, Total Cancelled
**********************/
drop table if exists #visitCountOfEachPaient;
SELECT t1.PID, count(*) TotalPastAppt
into #visitCountOfEachPaient
FROM #allHCHPApptsEver t1
GROUP BY t1.PID

drop table if exists #totalCancellations;
select h.pid, x.TotalCancelled
into #totalCancellations
from cps_hchp.tmp_view_HCHPClients h
	left join
	(
		SELECT t1.PID, count(*) TotalCancelled
		FROM #allHCHPApptsEver t1
		WHERE t1.Canceled = 1
		GROUP BY t1.PID
	) x on x.pid = h.PID
/***************
select * from cps_hchp.tmp_view_HCHPClients							967
select * from #allHCHPApptsEver						
select * from #lastVisitOfEachPatient				967
select * from #first_visit_each_patient				967
select * from #visitCountOfEachPaient				967
select * from #totalCancellations					967

need to add cbcm bit

consecutive cacellations - this is "gaps and island" problem
**********************/
drop table if exists #ConsecutiveStatusGapAndIslandProblem;
;with groupByCancelAndNotCancel AS (
	SELECT 
		conscutiveStatus = ROW_NUMBER() OVER (PARTITION BY t1.PID,t1.Canceled ORDER BY t1.apptDate DESC)
		,t1.PID,t1.Canceled,t1.ApptNum
	FROM #allHCHPApptsEver t1
), totalConsecutive AS (
	SELECT PID, COUNT(*) TotalConsecutive, Canceled
	FROM groupByCancelAndNotCancel
	where conscutiveStatus = ApptNum
	GROUP BY PID,Canceled
) --select * from totalConsecutive 
	SELECT q.PID, 
		q.Canceled, q.TotalConsecutive,
		case when q.Canceled = 1 then q.TotalConsecutive * -1
		else q.TotalConsecutive
		end ConsecApptStatus
	into #ConsecutiveStatusGapAndIslandProblem
	FROM totalConsecutive q

/***************
select * from cps_hchp.tmp_view_HCHPClients							967
select * from #allHCHPApptsEver						
select * from #lastVisitOfEachPatient				967
select * from #first_visit_each_patient				967
select * from #visitCountOfEachPaient				967
select * from #totalCancellations					967
select * from #ConsecutiveStatusGapAndIslandProblem	967

need to add cbcm bit

last not cancelled appt
**********************/
drop table if exists #DaysSinceLastVisit
;with notCancelledAppt as (
	select 
		t1.pid,t1.apptdate, t1.Facility LastSeenLoC, 
		LastNum = ROW_NUMBER() OVER (PARTITION BY t1.PId ORDER BY t1.apptdate DESC),
		t1.[Provider] LastSeenProvider
	from #allHCHPApptsEver t1
	where t1.Canceled != 1 OR t1.Canceled IS NULL
)
	SELECT h.pid, CONVERT(DATE,r.apptdate) LastSeenAppt, LastSeenProvider, LastSeenLoC
	into #DaysSinceLastVisit
	FROM cps_hchp.tmp_view_HCHPClients h
	left join notCancelledAppt r on r.PID = h.PID and r.LastNum = 1

/***************
select * from cps_hchp.tmp_view_HCHPClients							967
select * from #allHCHPApptsEver						
select * from #lastVisitOfEachPatient				967
select * from #first_visit_each_patient				967
select * from #visitCountOfEachPaient				967
select * from #totalCancellations					967
select * from #ConsecutiveStatusGapAndIslandProblem	967
select * from #DaysSinceLastVisit					967

need to add cbcm bit

future appt
**********************/

drop table if exists #u;
; with FutureAppts as (
SELECT 
	t2.pid,
	app.apptdate,app.DoctorFacilityID, app.FacilityID NextLoC, 
	FutureNum = ROW_NUMBER() OVER (PARTITION BY  t2.PID ORDER BY app.apptdate)
FROM #lastVisitOfEachPatient t2
	inner JOIN [CpsWarehouse].[cps_visits].Appointments app ON t2.pid = app.pid
	inner JOIN [CpsWarehouse].[cps_all].DoctorFacility df ON app.DoctorFacilityID = df.DoctorFacilityID
WHERE app.ApptDate >= CONVERT(DATE,GETDATE())
	AND df.JobTitle in ('Therapist','Psychiatrist','Psychologist') 
) --select * from FutureAppts
, NextApptDate as (
SELECT t6.PID,t6.ApptDate NextAppt, df.ListName NextProvider, NextLoC
FROM FutureAppts t6
	inner JOIN [CpsWarehouse].[cps_all].DoctorFacility df ON t6.DoctorFacilityID = df.DoctorFacilityId
WHERE t6.FutureNum = 1
) --select * from NextApptDate
, TotalFutureAppts as  (
SELECT t6.PID, COUNT(*) FutureScheduledAppt
FROM FutureAppts t6
GROUP BY t6.PID
) --select * from TotalFutureAppts

SELECT 
	h.pid,

	t10.FirstProvider, t10.FirstLoC, t10.FirstAppt, 

	t2.LastProvider,t2.LastLoC LastLoC,t2.LastAppt,
	t2.LastRegistrationStatus,
	t2.LastCanceled,
	t5.ConsecApptStatus, 

	t9.LastSeenProvider, t9.LastSeenAppt, t9.LastSeenLoC,
	t7.NextProvider, t7.NextAppt, t7.NextLoC,

	t3.TotalPastAppt,
	ISNULL(t4.TotalCancelled,0) TotalCanceled,
	t3.TotalPastAppt - ISNULL(t4.TotalCancelled,0) TotalNotCanceled,
	isnull(t8.FutureScheduledAppt,0) TotalFutureAppt
into #u
FROM cps_hchp.tmp_view_HCHPClients h
	left join #lastVisitOfEachPatient t2 on h.PID = t2.PID
	LEFT JOIN #visitCountOfEachPaient t3 on t2.PID = t3.PID
	LEFT JOIN #totalCancellations t4 on t2.PID = t4.PID
	LEFT JOIN #ConsecutiveStatusGapAndIslandProblem t5 ON t2.PID = t5.PID
	LEFT JOIN NextApptDate t7 ON t2.PID = t7.PID
	LEFT JOIN TotalFutureAppts t8 ON t2.PID = t8.PID
	LEFT JOIN #DaysSinceLastVisit t9 ON t2.PID = t9.PID
	left join cps_all.PatientProfile pp on pp.pid = t2.PID
	left join #first_visit_each_patient t10 on t10.PID = t2.PID

--select * into #temp from u
--exec tempdb.dbo.sp_help N'#u'

 insert into [cps_hchp].[HCHP_Patient_Appointments] ([PID],[LastProvider],[LastLoC],[LastAppt],
	[LastRegistrationStatus],[LastCanceled],[ConsecApptStatus],[FirstProvider],[FirstLoC],
	[FirstAppt],[LastSeenProvider],[LastSeenLoC],[LastseenAppt],[NextProvider],[NextLoC],
	[NextAppt],[TotalPastAppt],[TotalCanceled],[TotalNotCanceled],[TotalFutureAppt])
select [PID],[LastProvider],[LastLoC],[LastAppt],
	[LastRegistrationStatus],[LastCanceled],[ConsecApptStatus],[FirstProvider],[FirstLoC],
	[FirstAppt],[LastSeenProvider],[LastSeenLoC],[LastseenAppt],[NextProvider],[NextLoC],
	[NextAppt],[TotalPastAppt],[TotalCanceled],[TotalNotCanceled],[TotalFutureAppt]
from #u




END
go
