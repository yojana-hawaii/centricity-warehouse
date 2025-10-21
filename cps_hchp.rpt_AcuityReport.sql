
use CpsWarehouse
go

drop proc if exists cps_hchp.rpt_AcuityReport;
go
create proc cps_hchp.rpt_AcuityReport
as
begin

	SELECT  pp.name,pp.PatientID
		  ,[AcuityDate]
		  ,[AcuityScore]
		  ,[AcuityCount]
		  ,[PsychHospitalCount]
		  ,[Interpretation]
		  ,[VisitPerMonth]
		  ,[VisitType]
		  ,[EncounterType]
		  ,[Years]
		  ,[January]
		  ,[February]
		  ,[March]
		  ,[April]
		  ,[May]
		  ,[June]
		  ,[July]
		  ,[August]
		  ,[September]
		  ,[October]
		  ,[November]
		  ,[December]
	  FROM [CpsWarehouse].[cps_hchp].[CBCM_AcuityScore] c
		left join cps_all.PatientProfile pp on pp.pid = c.pid
	where TestPatient = 0
		--order by Years

end

go
