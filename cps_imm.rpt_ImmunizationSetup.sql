
use CpsWarehouse
go
drop proc if exists cps_imm.rpt_ImmunizationSetup;
go
create proc cps_imm.rpt_ImmunizationSetup
as
begin

	select 
		Vaccine, VaccineCVX, Brand, BrandCVX, BodySite, Dose, 
		NDC,  
		Route, Unit, 
		OrderDescription,  ICD10Code,
		isnull([1],'n/a') Series_1,
		isnull([2],'n/a') Series_2,
		isnull([3],'n/a') Series_3,
		isnull([4],'n/a') Series_4,
		isnull([5],'n/a') Series_5,
		isnull([6],'n/a') Series_6,
		isnull([7],'n/a') Series_7,
		isnull([8],'n/a') Series_8,
		isnull([9],'n/a') Series_9
	from 
	(
		select distinct 
			Vaccine, VaccineCVX, Brand, BrandCVX, BodySite, Dose, NDC,  Route, Unit, 
			Series,
			isnull(Series_Min_Age + ' (Min_Age) ','') +
			isnull(Series_Max_age + ' (Max_Age) ','') +
			isnull(Series_Interval + ' (Interval) ','') SeriesDetails,
			OrderDescription,  ICD10Code
		from cps_imm.ImmunizationSetup
	) q 
	pivot (
		max(SeriesDetails)
		for series in ([1],[2],[3],[4],[5],[6],[7],[8],[9])
	) pvt

end
go
