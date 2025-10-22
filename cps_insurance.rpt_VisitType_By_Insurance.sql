USE CpsWarehouse
go


drop PROCEDURE if exists [cps_insurance].[rpt_VisitType_By_Insurance] 

go
create procedure [cps_insurance].[rpt_VisitType_By_Insurance] 
	(
		@Startdate DATE,
		@Enddate DATE,
		@Insurance nvarchar(20),
		@VisitType nvarchar(10),
		@Loc nvarchar(20)
	)
AS
BEGIN


--	DECLARE @startdate DATE = '03-1-2017', @EndDate DATE = '3-31-2017', @insurance nvarchar(20) = 'united'/*united, hmsa*/, @VisitType nvarchar(10) = 'all'/*all,same day, er, hospital*/, @loc nvarchar(20) = 'All';

declare @major_insurance varchar(30) = case when @Insurance = 'All' then null else @Insurance end;
SELECT distinct
     pp.[PatientID]
      ,pp.[Name]
      ,pp.[DoB]
      ,ic.InsuranceName
      ,ins.PrimInsuranceNumber
	  ,ISNULL(CONVERT(VARCHAR,ins.PrimEffectiveDate),'') InsEffectiveDate
	  ,a.created ApptCreated
--	  ,CONVERT(TIME,a.created) ApptCreatedTime
	  ,a.ApptDate
	  ,a.StartTime ApptTime
	  ,a.ApptStatus
	  ,a.ApptType
	  ,df.ListName ApptUser, loc.Facility
	--  ,(CASE WHEN df.ListName != '' THEN df.ListName  ELSE a.resource END ) Resources
	--  ,a.PrimaryInsurance BillingIns
  FROM CpsWarehouse.cps_all.PatientProfile pp
	left join CpsWarehouse.cps_visits.Appointments a on a.pid = pp.pid
	left join CpsWarehouse.cps_all.PatientInsurance ins on ins.PID = pp.PID
	left join CpsWarehouse.cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.PrimCarrierID
	left join CpsWarehouse.cps_all.DoctorFacility df on df.DoctorFacilityID = a.DoctorFacilityID
	left join CpsWarehouse.cps_all.Location loc on loc.FacilityID = a.FacilityID
  WHERE --ic.InsuranceName like case when @Insurance = 'All' then '%' else '%' + @Insurance + '%' end--'united%'
	  ic.Classify_Major_Insurance = isnull(@major_insurance, ic.Classify_Major_Insurance)
	  and a.ApptDate >= @StartDate and a.ApptDate <= @EndDate
	  and a.ApptStatus NOT IN ('Cancel/Facility Error','Data Entry Error')
	  and a.ApptType like case when @VisitType = 'All' then '%' else '%' + @VisitType + '%' end
	  and loc.Facility like case when @Loc = 'All' then '%' else @Loc end



END

go
