use CpsWarehouse
go


/*Pysch 25290, therapist 277131, casemanager- 44679, outside - 445575 for patient*/
DROP view if exists  cps_hchp.tmp_view_HCHPClients;
go
create view cps_hchp.tmp_view_HCHPClients
as
	with case_mngr_assigned as (
		select  pp.PID
		from cps_all.PatientProfile pp 
		where pp.Old_CaseManager is not null 
			or pp.CBCM is not null 
			or pp.HF_Case_Manager is not null 
			or pp.HF_Housing_Specialist is not null
			or pp.Outreach is not null
	)
	, carf_dashboard as (
		SELECT  distinct obs.PID PID
		FROM [cpssql].[CentricityPS].[dbo].OBS
		WHERE HDID IN (462650/*acuity*/,298426/*type -face to face, phone etc*/,66473/*amhd css etc*/)
			or (hdid = 489709 and obsvalue in ('CBCM', 'outreach', 'housing first') ) /*carf specialty at the top*/
	) 
	, appointments as (
		SELECT 	distinct app.pid
		FROM [CpsWarehouse].[cps_visits].Appointments app 
		WHERE 
			app.InternalReferral = 'HCHP'
			and ApptStatus not in ('Data Entry Error','Cancel/Facility Error')
	)
	,all_hchp as (
	select distinct
		case when c.pid is null and d.pid is null then a.PID
			when c.pid is null and c.pid is null then d.pid 
		else c.pid end PID, 
		case when c.pid is null and d.pid is null then 'appointment type'
			when c.pid is null and c.pid is null then 'acuity / hchp visit carf dash'
		else 'case manager selected' end Reason
	from case_mngr_assigned c
		full outer join carf_dashboard d on d.pid = c.PID
		full outer join appointments a on d.pid = c.PID
	)
		select pp.Name,h.PID, h.Reason, pp.PatientID, pp.Therapist, pp.PCP, pp.Psych, pp.ExternalProvider,
			pp.Outreach, 
			pp.HF_Case_Manager, 
			pp.HF_Housing_Specialist, 
			pp.CBCM, 
			pp.Old_CaseManager
		from all_hchp h
			inner join cps_all.PatientProfile pp on pp.pid = h.PID 
		where TestPatient = 0


go
