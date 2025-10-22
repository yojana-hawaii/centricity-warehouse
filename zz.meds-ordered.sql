

use CpsWarehouse


declare @StartDate date = '2019-01-01';

with raw_data as (
	select 
		--df.ListName, df.PVID, 
		--df.Specialty, 
		Description, GenericMed, GPI, ltrim(rtrim(Instructions)) Instructions 
	from cps_meds.PatientMedication med
		--left join cps_all.DoctorFacility df on med.PubUser = df.PVID
	where med.ClinicalDate >= @StartDate
		and GPI is not null 
	--	and ListName is not null 

)
--	select * from raw_data
, cnt as (
	select 
		gpi,genericMed, Description 
		--,ListName, pvid 
		--,Specialty  
		,count(*) Total
	from raw_data
	group by 
		gpi,genericMed, Description 
		--,ListName, pvid
		--, Specialty
	having count(*) > 100
)
, instr as (
	select  GPI, instructions Instructions, count(*) totalInstruction
		--, pvid, listname
		--,Specialty
	from raw_data
	group by GPI, Instructions
		--, pvid, listname
		--,specialty
	having count(*) > 100
)

	select 
		--cnt.ListName, cnt.pvid, 
		--cnt.Specialty, 
		cnt.GPI, cnt.GenericMed, cnt.Description,
		cnt.Total TotalPrescriptionCount,  
		r.Instructions, r.totalInstruction
	from cnt
		left join instr r on r.GPI = cnt.gpi 
								--and r.PVID = cnt.PVID
								--and r.Specialty = cnt.Specialty

	order by cnt.genericMed, cnt.total desc	, r.totalInstruction desc


