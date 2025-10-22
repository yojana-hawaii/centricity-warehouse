


USE CpsWarehouse
go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

drop PROCEDURE if exists [cps_insurance].[rpt_Two_Year_Immunization] 

go
create procedure [cps_insurance].[rpt_Two_Year_Immunization] 
	(
		@StartDate DATE,
		@EndDate DATE,
		@Insurance nvarchar(20)
	)
AS
BEGIN



	--declare @Startdate date = '2021-01-01', @Enddate date = '2021-6-30', @Insurance varchar(30) = 'HMSA';

	/*immunization*/
	declare @ImmunDobStart datetime2 = dateadd(year, -2, @Startdate); 
	declare @ImmunDobEnd datetime2 = dateadd(year,-2, @Enddate);


	drop table if exists #ins
	select distinct 
		pp.PID, pp.PatientID, pp.DoB, prim.InsuranceName 
	into #ins
	from cps_all.PatientProfile pp
		left join cps_all.PatientInsurance ins on ins.PID = pp.PID
		left join cps_all.InsuranceCarriers prim on prim.InsuranceCarriersID = ins.PrimCarrierID
	where pp.DoB >= @ImmunDobStart and pp.DoB <= @ImmunDobEnd
		and prim.Classify_Major_Insurance = @Insurance
		and pp.TestPatient = 0;


	--declare @Startdate date = '2021-01-01', @Enddate date = '2021-6-30', @Insurance varchar(30) = 'HMSA';

	select 
		i.pid, i.PatientId, i.DoB, i.InsuranceName,

		isnull(max(dtap.Series),0) DtapTotal, 
		isnull(max(hepb.Series),0) HepBTotal, 
		isnull(max(hib.Series),0) HibTotal, 
		isnull(max(mmr.Series),0) MMRTotal, 
		isnull(max(pneumoPCV.Series),0) pneumoPCVTotal, 
		isnull(max(polio.Series),0) PolioTotal, 
		isnull(max(varicella.series),0) VaricellaTotal,

		max(case when dtap.Series = 1 then dtap.AdministeredDate end) Dtap1,
		max(case when dtap.Series = 2 then dtap.AdministeredDate end) Dtap2,
		max(case when dtap.Series = 3 then dtap.AdministeredDate end) Dtap3,
		max(case when dtap.Series = 4 then dtap.AdministeredDate end) Dtap4,

		max(case when hepb.Series = 1 then hepb.AdministeredDate end) HepB1,
		max(case when hepb.Series = 2 then hepb.AdministeredDate end) HepB2,
		max(case when hepb.Series = 3 then hepb.AdministeredDate end) HepB3,

		max(case when hib.Series = 1 then hib.AdministeredDate end) Hib1,
		max(case when hib.Series = 2 then hib.AdministeredDate end) Hib2,
		max(case when hib.Series = 3 then hib.AdministeredDate end) Hib3,
		
		max(case when mmr.Series = 1 then mmr.AdministeredDate end) MMR,

		max(case when pneumoPCV.Series = 1 then pneumoPCV.AdministeredDate end) pneumoPCV1,
		max(case when pneumoPCV.Series = 2 then pneumoPCV.AdministeredDate end) pneumoPCV2,
		max(case when pneumoPCV.Series = 3 then pneumoPCV.AdministeredDate end) pneumoPCV3,
		max(case when pneumoPCV.Series = 4 then pneumoPCV.AdministeredDate end) pneumoPCV4,

		max(case when polio.Series = 1 then polio.AdministeredDate end) polio1,
		max(case when polio.Series = 2 then polio.AdministeredDate end) polio2,
		max(case when polio.Series = 3 then polio.AdministeredDate end) polio3,

		max(case when varicella.Series = 1 then varicella.AdministeredDate end) varicella

	from #ins i
		left join cps_imm.ImmunizationWithCombo dtap on i.pid = dtap.PID and dtap.VaccineGroup = 'DTap' and dtap.AdministeredDate <= @EndDate
		left join cps_imm.ImmunizationWithCombo hepb on i.pid = hepb.PID and hepb.VaccineGroup = 'Hepatitis B' and hepb.AdministeredDate <= @EndDate
		left join cps_imm.ImmunizationWithCombo hib on i.pid = hib.PID and hib.VaccineGroup = 'HiB' and hib.AdministeredDate <= @EndDate
		left join cps_imm.ImmunizationWithCombo mmr on i.pid = mmr.PID and mmr.VaccineGroup = 'MMR' and mmr.AdministeredDate <= @EndDate
		left join cps_imm.ImmunizationWithCombo pneumoPCV on i.pid = pneumoPCV.PID and pneumoPCV.VaccineGroup = 'pneumoPCV' and pneumoPCV.AdministeredDate <= @EndDate
		left join cps_imm.ImmunizationWithCombo polio on i.pid = polio.PID and polio.VaccineGroup = 'polio' and polio.AdministeredDate <= @EndDate
		left join cps_imm.ImmunizationWithCombo varicella on i.pid = varicella.PID and varicella.VaccineGroup = 'varicella' and varicella.AdministeredDate <= @EndDate
	--where i.PatientId in (12103946,12103923)
	group by i.pid, i.PatientId, i.DoB, i.InsuranceName
end

go
