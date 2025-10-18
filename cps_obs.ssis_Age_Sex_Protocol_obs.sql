
use CpsWarehouse
go

drop table if exists [CpsWarehouse].[cps_obs].[Age_Sex_Protocol_obs];
create table [CpsWarehouse].[cps_obs].Age_Sex_Protocol_obs (
	[Age_Sex_Protocol_Obs_Guid] uniqueidentifier default newid(),
	[PID] [numeric](19, 0) NOT NULL,
	[ObsDate] date not null,
	[Chlamydia] varchar(15) null,
	[Mammogram] varchar(15) null,
	[PapSmear] varchar(15) null,
	[Colonoscopy] varchar(15) null,
	[IFobt] varchar(15) null,
	[IFobt_Decline] varchar(15) null,
	[FitDNA] varchar(15) null,
	[Sigmoidscopy] varchar(15) null,
	[Tomography] varchar(15) null,
	[Functional_ADL] varchar(15) null,
	[Functional_IADL] varchar(15) null,
	[Osteo_fracture] varchar(100) null,
	[BoneDensity] varchar(15) null,
	[BoneDensitySpine] varchar(15) null,
	[BoneDensityLeft] varchar(15) null,
	[BoneDensityRight] varchar(15) null,
)
go




drop proc if exists cps_obs.ssis_Age_Sex_Protocol_obs;
go

create proc cps_obs.ssis_Age_Sex_Protocol_obs
as
begin

truncate table [cps_obs].[Age_Sex_Protocol_obs];

with u as (
		select 
			pvt.PID, ObsDate, 
			[6857] [Chlamydia],
			[71] [Mammogram],
			[73] [PapSmear],
			[2323] [Colonoscopy],
			[97538] [IFobt],
			[276237] [IFobt_Decline],
			[582703] [FitDNA],
			[33934] [Sigmoidscopy],
			[585346] [Tomography],
			[93617] [Functional_ADL],
			[93620] [Functional_IADL],
			[31578] [Osteo_Fracture],
			[6528] [BoneDensity],
			[221415] [BoneDensitySpine],
			[83574] [BoneDensityLeft],
			[83573] [BoneDensityRight]
		from (
				select lastObs.PID, lastObs.ObsDate, lastObs.HDID, convert(varchar(10), obs.OBSVALUE) ObsValue
				from 
					(
						select  obs.PID PID, cast(obs.obsdate as date) obsdate, obs.HDID, max(obs.obsid)  ObsId
						from cpssql.CentricityPS.dbo.obs
						where obs.hdid in (
											6857, /*Chlamydia*/
											71, /*mammogram*/
											73, /*pap smear*/
											2323, /*Colonoscopy*/
											97538, /*ifobt*/
											276237, /*ifobt decline*/
											582703, /*fit dna*/
											33934, /*sigmoid*/
											585346, /*tomo*/
											93617, /*adl*/
											93620, /*iadl*/
											31578, /*fracture*/
											6528,/*bone density*/
											221415, /*bone spine*/
											83574, /*bone left*/
											83573 /*bone right*/
											)
							and obs.xid = 1000000000000000000		-- remove replaced value
						group by obs.pid, cast(obs.obsdate as date), obs.hdid
					) lastObs
					left join cpssql.CentricityPS.dbo.obs on obs.OBSID = lastObs.ObsId 
																and obs.obsvalue not like 'RES%'
				) t
				pivot (
					max(ObsValue)
					for hdid in ([6857], [71], [73], [2323], [97538], [276237], [582703], [33934], 
						[585346], [93617], [93620],[31578],[6528],[221415],[83574],[83573]
						)
			) pvt
	)
	insert into [cps_obs].[Age_Sex_Protocol_obs] (
		[PID], [ObsDate], [Chlamydia], [Mammogram], [PapSmear], [Colonoscopy], 
		[IFobt], [IFobt_Decline], [FitDNA], [Sigmoidscopy], [Tomography], 
		[Functional_ADL], [Functional_IADL],
		[Osteo_Fracture],[BoneDensity],[BoneDensitySpine],[BoneDensityLeft],[BoneDensityRight]
	)
	select
		[PID], [ObsDate], [Chlamydia], [Mammogram], [PapSmear], [Colonoscopy], 
		[IFobt], [IFobt_Decline], [FitDNA], [Sigmoidscopy], [Tomography], 
		[Functional_ADL], [Functional_IADL],
		[Osteo_Fracture],[BoneDensity],[BoneDensitySpine],[BoneDensityLeft],[BoneDensityRight]
	from u;


end
go
