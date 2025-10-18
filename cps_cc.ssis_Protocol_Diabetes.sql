
use CpsWarehouse
go
drop table if exists [cps_cc].[Protocol_Diabetes];
go
CREATE TABLE [cps_cc].[Protocol_Diabetes] (
    [PID]                NUMERIC (19) NOT NULL,
    [DiabType]           INT          NOT NULL,
    [LastA1c]            DATE         NULL,
    [A1c_DueIn]          INT          NOT NULL,
    [LastLDL]            DATE         NULL,
    [LDL_DueIn]          INT          NOT NULL,
    [LastCreatinine]     DATE         NULL,
    [Creatinine_DueIn]   INT          NOT NULL,
    [LastMicroalbumin]   DATE         NULL,
    [Microalbumin_DueIn] INT          NOT NULL,
    [LastDiabFoot]       DATE         NULL,
    [DiabFoot_DueIn]     INT          NOT NULL,
    [LastDiabDental]     DATE         NULL,
    [DiabDental_DueIn]   INT          NOT NULL,
    [LastDiabSMG]        DATE         NULL,
    [DiabSMG_DueIn]      INT          NOT NULL,
    [LastDiabEye]        DATE         NULL,
    [DiabEye_DueIn]      INT          NOT NULL,
    [DiabEyeType]        VARCHAR (20) NULL,
    PRIMARY KEY CLUSTERED ([PID] ASC)
);

go
drop proc if exists [cps_cc].[ssis_Protocol_Diabetes]
go

CREATE procedure [cps_cc].[ssis_Protocol_Diabetes]
as begin

truncate table [cps_cc].[Protocol_Diabetes];

	drop table if exists #lastProtocol;
	select 
		p.PID, p.DiabE10_E11,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs a1c
			where a1c.pid = p.PID and a1c.A1C is not null
		) LastA1C,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs obs
			where obs.pid = p.PID and obs.LDL is not null
		) LastLDL,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs obs
			where obs.pid = p.PID and obs.Creatinine is not null
		) LastCreatinine,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs obs
			where obs.pid = p.PID and obs.Microalbumin is not null
		) LastMicroalbumin,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs obs
			where obs.pid = p.PID and obs.Diab_Dental is not null
		) LastDiabDental,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs obs
			where obs.pid = p.PID and obs.Diab_Foot is not null
		) LastDiabFoot,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs obs
			where obs.pid = p.PID and obs.Diab_SMG is not null
		) LastDiabSMG,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs obs
			where obs.pid = p.PID and obs.Dojo_Eye is not null
		) LastDiabEye_Dojo,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs obs
			where obs.pid = p.PID and obs.Eye_pacs is not null
		) LastDiabEye_EyePac,
		(
			select max(ObsDate)
			from cps_obs.Diabetes_Obs obs
			where obs.pid = p.PID and obs.Scanned_Eye is not null
		) LastDiabEye_Scanned
	into #lastProtocol
	from cps_cc.[tmp_view_Protocol_PatientsList] p
	where p.DiabE10_E11 > 0
		--and p.pid in (
		--	1499090366750010,
		--	1499090230700010,
		--	1594119911000010,
		--	1618226903000010,
		--	1499090807100010,
		--	1799837993163330
		--	)


	declare 
		@a1c int = 90, 
		@OneYear int = 365,
		@dental int = 180;
		 --@today date = convert(date, getdate() );
	drop table if exists #protocol_next_due;
	select 
		p.pid, p.DiabE10_E11,
		p.LastA1C, fxn.ProtocolNextDueDate(p.LastA1C, @a1c) NextA1c, 
		p.LastLDL, fxn.ProtocolNextDueDate(p.LastLDL, @OneYear) NextLDL,
		p.LastCreatinine, fxn.ProtocolNextDueDate(p.LastCreatinine, @OneYear) NextCreatinine,
		p.LastMicroalbumin, fxn.ProtocolNextDueDate(p.LastMicroalbumin, @OneYear) NextMicroAlbumin,

		p.LastDiabFoot, fxn.ProtocolNextDueDate(p.LastDiabFoot, @OneYear) NextDiabFoot,
		p.LastDiabDental, fxn.ProtocolNextDueDate(p.LastDiabDental, @dental) NextDiabDental,
		p.LastDiabSMG, fxn.ProtocolNextDueDate(p.LastDiabSMG, @OneYear) NextDiabSMG,

		p.LastDiabEye_Dojo, fxn.ProtocolNextDueDate(p.LastDiabEye_Dojo, @OneYear) NextDiabEye_Dojo,
		p.LastDiabEye_EyePac, fxn.ProtocolNextDueDate(p.LastDiabEye_EyePac, @OneYear) NextDiabEye_EyePac,
		p.LastDiabEye_Scanned, fxn.ProtocolNextDueDate(p.LastDiabEye_Scanned, @OneYear) NextDiabEye_Scanned,

		case 
			when isnull(LastDiabEye_Dojo,'') >= isnull(LastDiabEye_EyePac,'') 
				and  isnull(LastDiabEye_Dojo,'') >= isnull(LastDiabEye_Scanned,'')
			then LastDiabEye_Dojo

			when isnull(LastDiabEye_EyePac,'') >= isnull(LastDiabEye_Dojo,'') 
				and  isnull(LastDiabEye_EyePac,'') >= isnull(LastDiabEye_Scanned,'')
			then LastDiabEye_EyePac

			when isnull(LastDiabEye_Scanned,'') >= isnull(LastDiabEye_EyePac,'') 
				and  isnull(LastDiabEye_Scanned,'') >= isnull(LastDiabEye_Dojo,'')
			then LastDiabEye_Scanned
		end LastDiabEye,

		case 
			when isnull(LastDiabEye_Dojo,'') >= isnull(LastDiabEye_EyePac,'') 
				and  isnull(LastDiabEye_Dojo,'') >= isnull(LastDiabEye_Scanned,'')
			then 'Dojo'

			when isnull(LastDiabEye_EyePac,'') >= isnull(LastDiabEye_Dojo,'') 
				and  isnull(LastDiabEye_EyePac,'') >= isnull(LastDiabEye_Scanned,'')
			then 'EyePac'

			when isnull(LastDiabEye_Scanned,'') >= isnull(LastDiabEye_EyePac,'') 
				and  isnull(LastDiabEye_Scanned,'') >= isnull(LastDiabEye_Dojo,'')
			then 'Scanned'
		end DiabEyeType

	into #protocol_next_due
	from #lastProtocol p;


	with u1 as (
		select 
			pid, 
			DiabE10_E11 DiabType,
			LastA1C, fxn.ProtocolPastDue(p.NextA1c) [A1C_DueIn],
			LastLDL, fxn.ProtocolPastDue(p.NextLDL) [LDL_DueIn],
			LastCreatinine, fxn.ProtocolPastDue(p.NextCreatinine) [Creatinine_DueIn],
			LastMicroalbumin, fxn.ProtocolPastDue(p.NextMicroAlbumin) [Microalbumin_DueIn],

			LastDiabFoot, fxn.ProtocolPastDue(p.NextDiabFoot) [DiabFoot_DueIn],
			LastDiabDental, fxn.ProtocolPastDue(p.NextDiabDental) [DiabDental_DueIn],
			LastDiabSMG, fxn.ProtocolPastDue(p.NextDiabSMG) [DiabSMG_DueIn],

			LastDiabEye, fxn.ProtocolNextDueDate(p.LastDiabEye, @OneYear) NextDiabEye,DiabEyeType
		from #protocol_next_due p
	)
	, u as (
		select
			PID, DiabType,
			LastA1C, A1C_DueIn,
			LastLDL, LDL_DueIn,
			LastCreatinine, Creatinine_DueIn,
			LastMicroalbumin, Microalbumin_DueIn,
			LastDiabFoot, DiabFoot_DueIn,
			LastDiabDental, DiabDental_DueIn,
			LastDiabSMG, DiabSMG_DueIn,
			LastDiabEye, fxn.ProtocolPastDue( NextDiabEye) DiabEye_DueIn,DiabEyeType
		from u1
	) --select * from u

		insert into [cps_cc].[Protocol_Diabetes] (
			PID, DiabType, LastA1c, A1c_DueIn, LastLDL, LDL_DueIn, LastCreatinine, 
			Creatinine_DueIn, LastMicroalbumin, Microalbumin_DueIn, 
			LastDiabFoot, DiabFoot_DueIn, LastDiabDental, DiabDental_DueIn, 
			LastDiabSMG, DiabSMG_DueIn, LastDiabEye, DiabEye_DueIn,DiabEyeType
		)
		select
			PID, DiabType, LastA1c, A1c_DueIn, LastLDL, LDL_DueIn, LastCreatinine, 
			Creatinine_DueIn, LastMicroalbumin, Microalbumin_DueIn, 
			LastDiabFoot, DiabFoot_DueIn, LastDiabDental, DiabDental_DueIn, 
			LastDiabSMG, DiabSMG_DueIn, LastDiabEye, DiabEye_DueIn,DiabEyeType
		from u ;

	END

go
