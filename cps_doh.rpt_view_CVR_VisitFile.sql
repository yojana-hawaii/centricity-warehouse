
use CpsWarehouse
go

drop view if exists cps_doh.rpt_view_CVR_VisitFile;

go

create view cps_doh.rpt_view_CVR_VisitFile
as

	SELECT DISTINCT
		f.pid, f.PatientId, C.DOS,c.SDID,
		c.[ClinicID 1-5], c.[SubID 6-2], c.[ClientID 8-20], c.[DoS 28-8], c.[ServiceProv 36-1], o.[Pregnancy Intention 37-1], 
		o.[Tobacco 38-1], o.[Alcohol 39-1], o.[Drug Use 40-1], o.[Domestic Violence 41-1], o.[PHQ2 42-1], o.[BMI 43-6], 
		o.[BP 49-1], o.[PelvicEx 50-1], 
		(CASE WHEN o.[Pap 51-1] = 'Y' OR c.[Pap 51-1] = 'Y' THEN 'Y' ELSE 'N' END) [Pap 51-1], 
		o.[TestaEx 52-1], o.[ClinicBreastEx 53-1], c.[FurtherBreast 54-1], o.[Pregnancy Result 55-1], 
		(CASE WHEN o.[ECPPartial 56-1] = 'Y' OR c.[EmergencyContra 56-1] = 'Y' THEN 'Y' ELSE 'N' END) [EmergencyContra 56-1], 
		c.[Chlam_test 57-1], c.[Chlam_Retest 58-1], c.[Gono_test 59-1], c.[Gono_Retest 60-1], o.[HIV Confidential 61-1], c.[Syphi_test 62-1],
		c.[Chlam_treat 63-1], c.[Gono_treat 64-1], c.[Syphi_treat 65-1], o.[CervCap 111-2 03] [CervCap 66-1],
		(CASE WHEN c.[IUDAdd 67-1] = 'Y' OR o.[IUDAdd 67-1] = 'Y' THEN 'Y' ELSE 'N' END) [IUDAdd 67-1],
		(CASE WHEN c.[IUDRemove 68-1] = 'Y' OR o.[IUDRemove 68-1] = 'Y' THEN 'Y' ELSE 'N' END) [IUDRemove 68-1],
		(CASE WHEN c.[ImplantAdd 69-1] = 'Y' OR o.[ImplanonAdd 69-1] = 'Y' THEN 'Y' ELSE 'N' END) [ImplanonAdd 69-1],
		(CASE WHEN c.[ImplantRemove 70-1] = 'Y' OR o.[ImplanonRemove 70-1] = 'Y' THEN 'Y' ELSE 'N' END) [ImplanonRemove 70-1],
		o.[ReproHealthEd 71-1], o.[InfertilityEd 72-1], o.[PreconceptionEd 73-1], o.[DVEd 74-1], o.[ReproLifePlanEd 75-1],
		o.[PregEd 76-1], o.[AdolescentEd 77-1], o.[OtherEd 78-1], o.[OtherEdSpec 79-30], o.[HIV/STD 109-1], o.[Condom Use 110-1],
		(CASE WHEN o.[Contraceptive 111-2] = '00' AND c.[DepoPartial 111-2 14] = 'Y' THEN '14' 
			WHEN  o.[Contraceptive 111-2] = '00' AND c.[OralContra 111-2 11] = 'Y' THEN '11' 
			WHEN  o.[Contraceptive 111-2] = '00' AND c.[Patch 111-2 15] = 'Y' THEN '15' 
			WHEN  o.[Contraceptive 111-2] = '00' AND c.[VaginaRing 111-2 16] = 'Y' THEN '16' 
			when o.[Contraceptive 111-2] = '99' then '  '
			ELSE O.[Contraceptive 111-2]
		END) [Contraceptive 111-2],
		o.[OtherContra 113-30], o.[NoReason 143-1], o.[NoMethodContra 144-30], 
		c.[ClinicID 1-5] + '-' [ClinicSiteID 174-6] ,  c.ProviderInitial [Prov Initial 180-6] 
	FROM  [CpsWarehouse].[cps_doh].rpt_view_FindCVRPatients f 
		left join [CpsWarehouse].[cps_doh].CVRClient x on x.PID = f.PID
		left JOIN [CpsWarehouse].[cps_doh].[CVRVisitClinicalList] c on ( x.ClientID = c.[ClientID 8-20] and x.SubID = c.[SubID 6-2]) 
		left JOIN [CpsWarehouse].[cps_doh].[CVRClientObs] o on (c.SDID = o.SDID)
	where [ClinicID 1-5] is not null



go
