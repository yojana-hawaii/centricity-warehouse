
use CpsWarehouse
go

drop proc if exists cps_bh .rpt_BH_PatientList
go
create proc cps_bh .rpt_BH_PatientList
as 
begin

	--drop table if exists #all_bh_patient;
	select 
		bh.PID, pp.PatientID, pp.Name, bh.Psych, bh.Therapist, pp.CBCM, pp.HF_Case_Manager, pp.HF_Housing_Specialist, pp.Outreach,
		FirstSeenAppt, LastScheduledAppt, LastseenAppt, LastSeenProvider, NextAppt, NextProvider,
		TotalCanceled, TotalNotCanceled, TotalFutureAppt
	--into #all_bh_patient
	from  cps_bh.BH_Patient bh
		left join cps_all.PatientProfile pp on pp.pid = bh.PID;


-- if need to add seen by specific providers
	/*
	drop table if exists #active_BH_Providers;
	select 
		distinct df.ListName, df.PVID
	into #active_BH_Providers
	from cps_all.DoctorFacility df 
	where 
		(
			df.JobTitle in ('Psychologist','Therapist','Psychiatrist')
			or df.Specialty in ('Behavioral Health', 'Psychiatry')
		)
		and HomeLocation != 'Kohou'
		and Billable = 1 
		and Inactive = 0;

	
	declare @startdate date = '2021-05-01', @enddate date = '2021-09-30'

	declare @start varchar(10) = convert(varchar(10), @startdate ),
		@end varchar(10) = convert(varchar(10), @enddate);
		declare @pivot_ready_active_provider nvarchar(max);
		select @pivot_ready_active_provider = '[' + left(Prov, len(Prov) - 3 ) 
		from (
			select ListName + '], [' 
			from #active_BH_Providers
			for xml path ('')
		) t (Prov);
	--	select @pivot_ready_active_provider


		drop table if exists ##provider_Appts;
		declare @sql nvarchar(max);
		set @sql = '
			select *	
			into ##provider_Appts
			from (
				select distinct ap.ListName, ap.PVID, ap.PID
				from cps_visits.Appointments ap
					inner join #active_BH_Providers bh on bh.PVID = ap.PVID
				where ap.ApptDate >= ''' + @start + '''
					and ap.ApptDate <= ''' + @end + '''
			) q
			pivot (
				max(pvid)
				for ListName in (' + @pivot_ready_active_provider + ')
			) pvt
		'
	--	print @sql

		exec (@sql)


	select 
		PID, Name, 
		PatientID, Psych, Therapist, CaseManager,
		FirstSeenAppt, LastScheduledAppt, LastseenAppt, LastSeenProvider, NextAppt, NextProvider,
		TotalCanceled, TotalNotCanceled, TotalFutureAppt 
	from #all_bh_patient bh 
		left join ##provider_Appts
*/
		

end
go
