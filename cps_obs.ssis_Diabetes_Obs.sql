
use CpsWarehouse
go
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO

drop table if exists [CpsWarehouse].[cps_obs].[Diabetes_Obs];
create table [CpsWarehouse].[cps_obs].Diabetes_Obs (
	[Diabetes_Obs_Guid] uniqueidentifier default newid(),
	[PID] [numeric](19, 0) NOT NULL,
	[ObsDate] date not null,
	[A1C] varchar(15) null,
	[LDL] varchar(15) null,
	[BloodGlucoseFasting] varchar(15) null,
	[BloodGlucoseRandom] varchar(15) null,
	[Creatinine] varchar(15) null,
	[Microalbumin] varchar(15) null,
	[Diab_Foot] varchar(15) null,
	[Diab_Dental] varchar(15) null,
	[Diab_SMG] varchar(15) null,
	[Dojo_Eye] varchar(15) null,
	[Scanned_Eye] varchar(15) null,
	[Eye_pacs] varchar(15) null,
	
) 
go



SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop proc if exists cps_obs.ssis_Diabetes_Obs;
go

create proc cps_obs.ssis_Diabetes_Obs
as
begin

truncate table [cps_obs].[Diabetes_Obs];

		/** get all necessary obs grouped by PID, HDID and obsdate
		  * get the largest ObsID - last value for the day
		  * pivot the result

		  * 1. add to where --> hdid
		  * 2. add to pivot for(hdid) --> [hdid]
		  * 3. add hdid to final select and rename  --> [hdid] Name
		  * 4. add to create table
		  * 5. update merge
		**/

	with u as (
		select 
			pvt.PID, ObsDate, 
			[28] [A1C],[7] [LDL],[8] [BloodGlucoseFasting],[18] [BloodGlucoseRandom],
			[30] [Creatinine],[13557] [Microalbumin],[2541] [Diab_Foot],
			[261088] [Diab_Dental],[13552] [Diab_SMG],[261] [Dojo_Eye],
			[145660] [Scanned_Eye],[2000009] [Eye_pacs]

		from (
				select lastObs.PID, lastObs.ObsDate, lastObs.HDID, convert(varchar(10), obs.OBSVALUE) ObsValue
				from 
					(
						select  obs.PID PID, cast(obs.obsdate as date) obsdate, obs.HDID, max(obs.obsid)  ObsId
						from cpssql.CentricityPS.dbo.obs
						where obs.hdid in (28, /*a1c*/
											7, /*blood glucose fasting*/
											8, /*blood glucose random*/
											18, /*creatinine*/
											30, /*ldl*/
											13557, /*microalbumin*/
											2541, /*foot*/
											261088, /*dental*/
											13552, /*smg*/
											261, /*scanned eye*/
											145660, /*eye pac*/
											2000009 /*dojo eye*/
											)
							and obs.xid = 1000000000000000000		-- remove replaced value
						group by obs.pid, cast(obs.obsdate as date), obs.hdid
					) lastObs
					left join cpssql.CentricityPS.dbo.obs on obs.OBSID = lastObs.ObsId 
																and obs.obsvalue not like 'RES%'
				) t
				pivot (
					max(ObsValue)
					for hdid in ([28], [7], [8], [18], [30], [13557], [2541], [261088], [13552], [261], [145660], [2000009])
			) pvt
	)
		insert into [cps_obs].[Diabetes_Obs](
			[PID], [ObsDate], [A1C], [LDL], [BloodGlucoseFasting], [BloodGlucoseRandom], [Creatinine], 
			[Microalbumin], [Diab_Foot], [Diab_Dental], [Diab_SMG], [Dojo_Eye], [Scanned_Eye], [Eye_pacs]
		)
		select
			[PID], [ObsDate], [A1C], [LDL], [BloodGlucoseFasting], [BloodGlucoseRandom], [Creatinine], 
			[Microalbumin], [Diab_Foot], [Diab_Dental], [Diab_SMG], [Dojo_Eye], [Scanned_Eye], [Eye_pacs]
		from u;

		end 
		
go


											