
use CpsWarehouse
go
drop view if exists cps_hl7.tmp_view_HL7_External_Source;
go
create view cps_hl7.tmp_view_HL7_External_Source
as
	select 
			e.EXT_CODE_ID,
			case  
				when CODING_SYSTEM_NAME in ('Corepoint-HDRS') then 'HDRS'
				when CODING_SYSTEM_NAME in ('LIS-DLS','L&DLS') then 'DLS-HPL'

				when CODING_SYSTEM_NAME in ('eScriptMessenger') then 'eScript'
				when CODING_SYSTEM_NAME in ('BRENTWOOD OBS','MIDMARK OBS') then 'Midmark'
				when CODING_SYSTEM_NAME in ('DocumentManagementLab','DocumentManagementLabSigned') then 'DocMan'
				when CODING_SYSTEM_NAME in ('LAB','LN') then 'CLH'
				when CODING_SYSTEM_NAME in ('LISignature') then 'eRegistration'
				else CODING_SYSTEM_NAME
			end Coding_System,
			CODING_SYSTEM_NAME,
			e.CODE Ext_Result_code,
			LOWER(e.DESCRIPTION) Ext_Result_Description, 
			e.DB_CREATE_DATE, e.DB_UPDATED_DATE
		FROM cpssql.[CentricityPS].dbo.EXT_CODE e

go
