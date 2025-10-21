



USE [CpsWarehouse]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


drop PROCEDURE if exists [cps_doh].rpt_CVR_ClientFile
 
go
create PROCEDURE [cps_doh].rpt_CVR_ClientFile 
	(
		@StartDate DATE,
		@EndDate DATE
	)
AS
BEGIN
--declare @startdate datetime = '2019-11-01', @enddate datetime = '2019-12-31'
SELECT DISTINCT
convert(nvarchar(max),
	x.ClinicID + x.SubID + x.ClientID + x.Sex + x.DoB +x.Zip + x.Race + x.Ethnicity + x.PovertyLevel + x.FamilySize + x.MonthlyIncome + 
	x.Black + x.Amr_Ind + x.White + x.Portugese + x.Pot_Mex + x.Chinese + x.Filipino + x.Japanese + x.Korean + x.Vietnamese + 
	x.Hawaiian + x.Samoan + x.Marshallese + x.Micronesian + x.Chuuk + x.Korsa + x.Pohn + x.Yap + x.Unknown + 
	x.Oth_Asian + x.Oth_AFree + x.Oth_OPI + x.Oth_PFree + x.Other + x.Oth_Free +
	x.Education + x.English + x.CompactFree + x.Insurance + x.Confidential) AS ClientFile
FROM  [CpsWarehouse].[cps_doh].rpt_view_FindCVRPatients f 
	left join [CpsWarehouse].[cps_doh].CVRClient x on x.PID = f.PID
	left JOIN [CpsWarehouse].[cps_doh].[CVRVisitClinicalList] c on ( x.ClientID = c.[ClientID 8-20] and x.SubID = c.[SubID 6-2]) 
	left JOIN [CpsWarehouse].[cps_doh].[CVRClientObs] o on (c.SDID = o.SDID)
WHERE c.DoS >= @StartDate AND 
	c.Dos <= @EndDate 
END
go
