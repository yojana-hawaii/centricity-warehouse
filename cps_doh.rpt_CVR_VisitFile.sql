
USE [CpsWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


drop PROCEDURE if exists [cps_doh].rpt_CVR_VisitFile
 
go
create PROCEDURE cps_doh.rpt_CVR_VisitFile 
	(
		@StartDate DATE,
		@EndDate DATE
	)
AS
BEGIN
--declare @startdate datetime = '2019-11-01', @enddate datetime = '2019-12-31'
SELECT DISTINCT
convert(nvarchar(max),
	f.[ClinicID 1-5] + f.[SubID 6-2] + f.[ClientID 8-20] + f.[DoS 28-8] + f.[ServiceProv 36-1] + f.[Pregnancy Intention 37-1] + 
	f.[Tobacco 38-1] + f.[Alcohol 39-1] + f.[Drug Use 40-1] + f.[Domestic Violence 41-1] + f.[PHQ2 42-1] + f.[BMI 43-6] + 
	f.[BP 49-1] + f.[PelvicEx 50-1] + f.[Pap 51-1] + 
	f.[TestaEx 52-1] + f.[ClinicBreastEx 53-1] + f.[FurtherBreast 54-1] + f.[Pregnancy Result 55-1] + 
	f.[EmergencyContra 56-1] +
	f.[Chlam_test 57-1] + f.[Chlam_Retest 58-1] + f.[Gono_test 59-1] + f.[Gono_Retest 60-1] + f.[HIV Confidential 61-1] + f.[Syphi_test 62-1] +
	f.[Chlam_treat 63-1] + f.[Gono_treat 64-1] + f.[Syphi_treat 65-1] + f.[CervCap 66-1] +
	[IUDAdd 67-1] + [IUDRemove 68-1] + f.[ImplanonAdd 69-1] + f.[ImplanonRemove 70-1] +
	f.[ReproHealthEd 71-1] + f.[InfertilityEd 72-1] + f.[PreconceptionEd 73-1] + f.[DVEd 74-1] + f.[ReproLifePlanEd 75-1] +
	f.[PregEd 76-1] + f.[AdolescentEd 77-1] + f.[OtherEd 78-1] + f.[OtherEdSpec 79-30] + f.[HIV/STD 109-1] + f.[Condom Use 110-1] +
	[Contraceptive 111-2] +
	f.[OtherContra 113-30] + f.[NoReason 143-1] + f.[NoMethodContra 144-30] + f.[ClinicSiteID 174-6] + f.[Prov Initial 180-6]) AS VisitFile
FROM  [CpsWarehouse].[cps_doh].rpt_view_CVR_VisitFile f 
	--left join [CpsWarehouse].[cps_doh].CVRClient x on x.PID = f.PID
	--left JOIN [CpsWarehouse].[cps_doh].[CVRVisitClinicalList] c on ( x.ClientID = f.[ClientID 8-20] and x.SubID = f.[SubID 6-2]) 
	--left JOIN [CpsWarehouse].[cps_doh].[CVRClientObs] o on (f.SDID = f.SDID)
WHERE f.DoS >= @StartDate AND 
	f.Dos <= @EndDate 
END

go
