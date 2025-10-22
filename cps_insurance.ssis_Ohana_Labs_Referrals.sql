
use CpsWarehouse
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
drop table if exists [CpsWarehouse].[cps_insurance].Ohana_Labs_Referrals;
go
create table [CpsWarehouse].[cps_insurance].Ohana_Labs_Referrals (
	[PID] [numeric](19, 0) NOT NULL,
	[Service_Performed] nvarchar(16) not null,
	[Service_Result] nvarchar(1000) not null,
	Service_Date date not null,
	DoctorFacilityID int not null
)

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_insurance].ssis_Ohana_Labs_Referrals; 
 
go
CREATE procedure [cps_insurance].ssis_Ohana_Labs_Referrals
as 
begin

	truncate table cps_insurance.Ohana_Labs_Referrals;

	/*Transition of care - hospital admited and seen within 30 days*/
	/*drop table if exists #toc
	select 
		er.PID, 'TRC' Service_Performed, 'yes' Service_Result , ApptDateInCPS ServiceDate, df.DoctorFacilityID
	into #toc
	from cps_cc.ER_Followup er
		left join cps_all.PatientInsurance ins on ins.PID = er.PID
		left join cps_all.InsuranceCarriers ic on ins.PrimCarrierID = ic.InsuranceCarriersID
		left join cps_all.DoctorFacility df on df.ListName = er.ApptProv
	where ER = 0
		and Actual_Qualified_Appt_Range in ('0_7','8_14','15_30')
		and ic.Classify_Major_Insurance = 'ohana'
		and DischargeDate >= '2019-01-01'
		and ins.PrimInsuranceNumber is not null
		and ins.PrimInsuranceNumber not in ('','none');
*/

	/*Ohana Labs from "zzOhana Labs & Referrals" flowsheet*/
	drop table if exists #OhanaLabs_Referrals_zzFlowsheet;
	select 
		FlowsheetName, HDID,  ObsTerm, 
		ltrim(rtrim(replace(FlowsheetCustomLabel, 'Ohana', ''))) OhanaCode
	into #OhanaLabs_Referrals_zzFlowsheet
	from cps_obs.Flowsheet_Recussive f 
	where  f.FlowsheetID = 1950531781627340
	--select * from #OhanaLabs_Referrals_zzFlowsheet


	/*get relevant obs from #relevantDocs and ohana service flowsheet*/
	drop table if exists #cleanup_and_AddPCP;
	;with get_relevant_obs as (
		select distinct
			obs.pid PID, convert(date, obs.obsdate) resultDate,
			ohana.OhanaCode Service_Performed, 
			lower(
				ltrim(rtrim(
					replace(
						replace(
							replace(
								replace(obs.obsvalue, ' MG/GM CREAT',''), 
							'MG ALB/G CRE', ''),
						'MG/G CREAT',''),
					'ug/dL','')
				))) Service_Result,
			df.DoctorFacilityID,
			ohana.HDID, ohana.ObsTerm
		from cpssql.CentricityPS.dbo.obs
			inner join #OhanaLabs_Referrals_zzFlowsheet ohana on ohana.HDID = obs.hdid
			inner join cps_all.PatientInsurance ins on ins.pid = obs.pid
			inner join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.PrimCarrierID
			inner join cps_all.DoctorFacility df on df.PVID = obs.pubuser
		where obs.obsdate >= '2019-01-01'
			and ic.Classify_Major_Insurance = 'Ohana' --and OhanaCode like '%bmd%'
			and ins.PrimInsuranceNumber is not null
			and ins.PrimInsuranceNumber not in ('','none')

		--union 

		--select PID, t.ServiceDate, t.Service_Performed, t.Service_Result, t.DoctorFacilityID, null hdid, null obsterm
		--from #toc t
	)
	
	select distinct
		u.PID,  Service_Performed, 
		case 
			--when Service_Performed = 'OMW' then 'Yes' /*OMW has BMD (dexa scan) and osteo (meds. meds are ignore. cannot verify if dispensed from pharmarcy 11-14-2022)*/
			when Service_Performed = 'DRE' and Service_Result like '%done%' then /*Service_Result*/'Yes' /*only done count. staff entered declined and scheduled etc. 11-14-2022*/
			when Service_Result in  ('see notes','see report') then 'Done' 
			else Service_Result 
		end Service_Result, 
		resultDate, 
		case when oh.DoctorFacilityID is not null then oh.DoctorFacilityID else oh2.DoctorFacilityID end DF
	into #cleanup_and_AddPCP
	from get_relevant_obs u
		left join cps_insurance.tmp_view_OhanaProviders oh on oh.DoctorFacilityID = u.DoctorFacilityID /*verify provider is approved*/
		left join cps_all.PatientProfile pp on pp.pid = u.PID
		left join cps_insurance.tmp_view_OhanaProviders oh2 on oh2.PVID = pp.PCP_PVID /*verify pcp is approved.*/
	where 
		(Service_Performed = 'DRE' and Service_Result like '%done%') /*only done count. staff entered declined and scheduled etc. 11-14-2022*/
		or Service_Performed != 'dre'
	--	--(Service_Result not like '%sche%' and Service_Result not like '%decl%' and Service_Result not like '%outside%')
	--)
	
	;with u as (
		select 
			PID, Service_Performed, Service_Result, resultDate, DoctorFacilityID
		from (
			select 
				pcp.PID,  Service_Performed, Service_Result, ResultDate,
				PVT.BilledProviderID DoctorFacilityID,
				RowNum = ROW_NUMBER() over( partition by pcp.PID, ResultDate 
											order by abs( datediff(day, pcp.resultDate, pvt.DoS) ) /*closest visit negative or postive days*/
										)			
			from #cleanup_and_AddPCP pcp
				left join cps_visits.PatientVisitType pvt on pvt.pid = pcp.pid 
			where df is null
				and datediff(day, pcp.resultDate, pvt.DoS) <= 30  
				and datediff(day, pcp.resultDate, pvt.DoS) >= -30
				and pvt.BilledProviderID in (select DoctorFacilityID from cps_insurance.tmp_view_OhanaProviders)
		) ClosestVisit
		where RowNum = 1

		union all
		select * 
		from #cleanup_and_AddPCP pcp
		where df is not null
	)
	insert into cps_insurance.Ohana_Labs_Referrals(PID,  Service_Performed, Service_Result, Service_Date, DoctorFacilityID)
	select 
		PID,  Service_Performed, Service_Result, ResultDate, DoctorFacilityID
	from u
	
	


end

go


