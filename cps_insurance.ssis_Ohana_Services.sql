
use CpsWarehouse
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
drop table if exists [CpsWarehouse].[cps_insurance].Ohana_Services;
create table [CpsWarehouse].[cps_insurance].Ohana_Services (
	[PID] [numeric](19, 0) NOT NULL,
	[SDID] [numeric](19, 0) NOT NULL,
	[Service_Performed] nvarchar(16) not null,
	[Service_Result] nvarchar(100) not null,
	[Service_Date] date not null,
)

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_insurance].ssis_Ohana_Services; 
 
go
CREATE procedure [cps_insurance].ssis_Ohana_Services
as 
begin

	truncate table cps_insurance.Ohana_Services;


	/*Ohana Services from "zzOhana Service" Flowsheet*/
	drop table if exists #OhanaServices_zzFlowsheet;
	select 
		FlowsheetName, HDID,  ObsTerm, 
		ltrim(rtrim(replace(FlowsheetCustomLabel, 'Ohana', ''))) OhanaCode
	into #OhanaServices_zzFlowsheet
	from cps_obs.Flowsheet_Recussive f 
	where  f.FlowsheetID = 1950531781627360
	--	select * from #OhanaServices_zzFlowsheet


	/*get relevant obs from #relevantDocs and ohana service flowsheet*/
	drop table if exists #relevant_obs;
	select distinct
		doc.pid, doc.SDID,
		ohana.OhanaCode Service_Performed, 
		obs.obsvalue Service_Result, convert(date,obs.ObsDate) Service_Date,
		ohana.HDID, ohana.ObsTerm
	into #relevant_obs
	from cps_insurance.tmp_view_OhanaEncounters doc
		inner join cpssql.CentricityPS.dbo.obs on obs.sdid = doc.sdid
		inner join #OhanaServices_zzFlowsheet ohana on ohana.HDID = obs.hdid;
	-- select * from #relevant_obs


	/*BP need to combine sys and dias & keep MU value when there are 2 BP*/
	drop table if exists #bp;
	; with BP_Combined as (
		select 
			PID, SDID, 'BPL-MU' Service_Performed, 
			pvt.[BPL-Sys] + '/' + pvt.[BPL-Dias] Service_Result, Service_Date,
			1 OrderOptions /*Row Number to get MU value when available else other value*/
		from (
			select 
				SDID, PID, Service_Performed, convert(varchar(10), Service_Result) Service_Result, Service_Date
			from #relevant_obs o
			where o.HDID in (355310, 355309)
		) q
		pivot (
			max(Service_Result)
			for Service_Performed in ([BPL-Sys],[BPL-Dias])
		) pvt
		where pvt.[BPL-Dias] is not null and pvt.[BPL-Sys] is not null

		union all

		select 
			PID, SDID, 'BPL-Sit' Service_Performed, 
			pvt.[BPL-Sys] + '/' + pvt.[BPL-Dias] Service_Result,Service_Date,
			2 OrderOptions
		from (
			select 
				SDID, PID, Service_Performed, convert(varchar(10), Service_Result) Service_Result, Service_Date
			from #relevant_obs o
			where o.HDID in (53, 54)
		) q
		pivot (
			max(Service_Result)
			for Service_Performed in ([BPL-Sys],[BPL-Dias])
		) pvt
		where pvt.[BPL-Dias] is not null and pvt.[BPL-Sys] is not null

		union all

		select 
			PID, SDID, 'BPL-Stand' Service_Performed, 
			pvt.[BPL-Sys] + '/' + pvt.[BPL-Dias] Service_Result,Service_Date,
			3 OrderOptions
		from (
			select 
				SDID, PID, Service_Performed, convert(varchar(10), Service_Result) Service_Result,Service_Date
			from #relevant_obs o
			where o.HDID in (2883, 2884)
		) q
		pivot (
			max(Service_Result)
			for Service_Performed in ([BPL-Sys],[BPL-Dias])
		) pvt
		where pvt.[BPL-Dias] is not null and pvt.[BPL-Sys] is not null

		union all

		select 
			PID, SDID, 'BPL-Lying' Service_Performed, 
			pvt.[BPL-Sys] + '/' + pvt.[BPL-Dias] Service_Result,Service_Date,
			4 OrderOptions
		from (
			select 
				SDID, PID, Service_Performed, convert(varchar(10), Service_Result) Service_Result,Service_Date
			from #relevant_obs o
			where o.HDID in (2885, 2886)
		) q
		pivot (
			max(Service_Result)
			for Service_Performed in ([BPL-Sys],[BPL-Dias])
		) pvt
		where pvt.[BPL-Dias] is not null and pvt.[BPL-Sys] is not null
	)
	, final_bp as (
		select 
			PID, SDID, 'BPL' Service_Performed, Service_Result,Service_Date,
			RowNum = ROW_NUMBER() over(partition by pid, sdid order by OrderOptions)
		from BP_Combined
	)
		select PID, SDID, Service_Performed, Service_Result,Service_Date
		into #bp
		from final_bp
		where RowNum = 1




	/*Services with numeric result - BMI * BMI percentile*/
	drop table if exists #numeric;
	select 
		PID, SDID, Service_Performed, convert(varchar(10), Service_Result) Service_Result, Service_Date
	into #numeric
	from #relevant_obs o
	where o.Service_Performed  in ('BMI-P', 'BMI-V')

	/*ML & MR should be same. if one is done and other is not done remove*/
	drop table if exists #ml_mr_same;
	select 
		distinct PID, SDID, Service_Performed, 'Yes' Service_Result,Service_Date
	into #ml_mr_same
	from #relevant_obs o 
	where Service_Performed  in ('MR', 'ML') 
		and o.SDID in (
			select 
				distinct ml.SDID
			from #relevant_obs ml
				left join #relevant_obs mr on mr.SDID = ml.SDID and mr.Service_Performed = 'ML'
			where ml.Service_Performed  in ('MR') and mr.SDID is not null
		)

	/*rest of services - Advanced directive need discussed, rest is simply yes*/
	drop table if exists #Remaining_Services;
	select distinct
		PID, SDID, Service_Performed,
		case 
			when Service_Performed = 'ACP' then 'Discussed' 
		else 'Yes' end Service_Result,Service_Date
	into #Remaining_Services
	from #relevant_obs o
	where o.Service_Performed not in ('BPL-Sys','BPL-Dias','BMI-P', 'BMI-V','MR', 'ML')


	
	/*combine all services*/
	;with u as (
		select  * from #bp
		union 
		select * from #numeric
		union 
		select * from #Remaining_Services
		union
		select * from #ml_mr_same
	) --select * from  u where Service_Result is null
	insert into cps_insurance.Ohana_Services (PID, SDID, Service_Performed, Service_Result, Service_Date)
	select PID, SDID, Service_Performed, Service_Result,Service_Date from u
	

end

go


