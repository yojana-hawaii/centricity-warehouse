
use CpsWarehouse
go
drop table if exists [cps_hl7].[all_HL7_Mapping];
go
CREATE TABLE [cps_hl7].[all_HL7_Mapping] (
    [Ext_Code_ID]            NUMERIC (19)   NOT NULL,
    [Coding_System]          NVARCHAR (50)  NOT NULL,
    [Ext_Result_Code]        NVARCHAR (50)  NOT NULL,
    [Ext_Result_Description] NVARCHAR (250) NOT NULL,
    [HDID]                   INT            NOT NULL,
    [ObsTerm]                NVARCHAR (16)  NOT NULL,
    [LoincCode]              NVARCHAR (12)  NULL,
    [MLCode]                 NVARCHAR (12)  NULL,
    [TotalUsed]              BIGINT         NOT NULL,
    [LastPID]                NUMERIC (19)   NOT NULL,
    [LastSDID]               NUMERIC (19)   NOT NULL,
    [LastObsID]              NUMERIC (19)   NOT NULL,
    [LastObsDate]            DATE           NOT NULL,
    [Mapping_Created]        DATETIME2 (7)  NOT NULL,
    [Mapping_Updated]        DATETIME2 (7)  NOT NULL,
	primary key clustered ([Ext_Code_ID] asc, [HDID] asc)
);

go
drop proc if exists [cps_hl7].[ssis_all_HL7_Mapping];
go
CREATE PROCEDURE [cps_hl7].[ssis_all_HL7_Mapping]
AS
BEGIN

	TRUNCATE TABLE [cps_hl7].[all_HL7_Mapping];

	drop table if exists #u;
	; with internal_mapping as (
		select 
			e.EXT_CODE_ID Ext_code_id, e.Coding_System, e.Ext_Result_code, e.Ext_Result_Description, 
			oh.HDID hdid, oh.NAME ObsTerm,  oh.LOINCCODE LOINCCODE, oh.MLCODE MLCODE, 
			count(*) TotalUsed , max(obs.obsid) obsid,max(obs.sdid) sdid,
			e.DB_CREATE_DATE Mapping_Created, e.DB_UPDATED_DATE Mapping_Updated
		from CpsWarehouse.cps_hl7.tmp_view_HL7_External_Source e
			INNER JOIN cpssql.[CentricityPS].dbo.REL_OBS_EXT_CODE r ON e.EXT_CODE_ID = r.EXT_CODE_ID
			INNER JOIN cpssql.[CentricityPS].dbo.OBS ON r.OBSID = obs.OBSID and obs.pubuser !=0
			INNER JOIN cpssql.[CentricityPS].dbo.OBSHEAD oh ON oh.HDID = obs.HDID
		group by e.EXT_CODE_ID, e.Coding_System, e.Ext_Result_code, e.Ext_Result_Description, e.DB_CREATE_DATE, e.DB_UPDATED_DATE, oh.HDID, oh.NAME,oh.LOINCCODE, oh.MLCODE
	) --select * from internal_mapping
		select 
			i.Ext_code_id, i.Coding_System, 
			i.Ext_Result_code,i.Ext_Result_Description, 
			i.hdid, i.ObsTerm, i.LOINCCODE, i.MLCODE, 
			obs.pid [LastPID], convert(date,obs.obsdate) [LastObsDate],
			i.sdid [LastSDID], i.ObsID [LastObsId], 
			i.Mapping_Created, i.Mapping_Updated, i.TotalUsed
		into #u
		from internal_mapping i
			INNER JOIN cpssql.[CentricityPS].dbo.OBS on obs.obsid = i.obsid

				--exec tempdb..sp_help #u

	insert into [cps_hl7].[all_HL7_Mapping]  (
		Ext_Code_ID,Coding_System,Ext_Result_Code,Ext_Result_Description,HDID,[LastPID],[LastSDID],[LastObsId],
		ObsTerm,LoincCode,MLCode,TotalUsed,LastObsDate,Mapping_Created,Mapping_Updated
	)
	select
		Ext_Code_ID,Coding_System,Ext_Result_Code,Ext_Result_Description,HDID,[LastPID],[LastSDID],[LastObsId],
		ObsTerm,LoincCode,MLCode,TotalUsed,LastObsDate,Mapping_Created,Mapping_Updated
	from #u
end
go
