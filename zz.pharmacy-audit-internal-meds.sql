

/*Get in-house medication administered by code*/
declare @startdate date = '2020-07-01',
			@enddate date = '2020-12-31';
--drop table #with_codes
;with possible_codes as (
	select cat.OrderCodeID, cat.OrderDesc, cat.OrderCode, cat.OrderType, cat.CategoryName
	from CpsWarehouse.cps_orders.OrderCodesAndCategories cat
	where cat.OrderDesc in (
			'J7619 Albuterol Neb Sol''n Unit Dose','95117 Allergy, multiple',
			'J7644 Atrovent Neb Sol''n Unit Dose','J3420 B12 IM (office supplied B12)','J0561 Injection, Penicillin G Benzathine (Bicillin LA)',
			'J1090 Depo -Testosterone 50 mg','J1050 Depo','J2100 Diphenhydramine (Benadryl) <=50mg','J7307 Nexplanon','90788 Injection, antibiotic',
			'J3301 Kenalog 10 mg','J1885 Ketorolac (Toradol) per 15mg','J1950 Lupron','90473 Oral Medication Administration-1',
			'J2550 Promethazine (Phenergan) <=50 mg','J0696 Rocephin 1000 mg','J0696 Rocephin 125 mg','J0696 Rocephin 250 mg',
			'J0696 Rocephin 500 mg','J3301 Triamcinolone/Kenalog','J1815 Injection, Insulin','J1700 Cortisone, Injection, hydrocortisone acetate, up to 25 mg',
			'J1710 Cortisone, Injection, hydrocortisone sodium phosphate, up to 50 mg','J1885 Injection, ketorolac tromethamine, per 15 mg',
			'J2175 Demerol, Injection, meperidine hydrochloride, per 100 mg','J2550 Phenergan Injection, promethazine hcl, up to 50 mg',
			'J3420 Injection, vitamin b-12 cyanocobalamin, up to 1000 mcg','J7301 Skyla 3 years duration; Levonorgestrel 13.5 mg','IM Injection Admin Code',
			'IM or SQ Injection','Med Administration (PO-SL-IN-PR)','IM Injection of Antibiotic','90473 Oral Medication Administration-1','Tylenol 80 mg/0.8 ml',
			'Tylenol 80 mg','Tylenol 160 mg','Tylenol 320 mg','Tylenol 500 mg','Ibuprofen 80 mg/0.8 ml','Ibuprofen 200 mg','NTG 0.4 mg','11981 Implanon Insertion',
			'11982 Implanon Removal','11983 Implanon, Removal with reinsertion','94640 Inhalation U/D (Nebulizer)','11976 Removal, implantable contraceptive capsules',
			'57061 Trichloroacetic Acid Tx','58300 Insertion of intrauterine device (IUD) - Mirena','58300 Insertion of intrauterine device (IUD) - Paragard',
			'58301 Removal of intrauterine device (IUD)','J7298 - Mirena 5 yr duration; Levonorgestrel 52mg',
			'J7300 - Paragard 10 yr duration (Intrauterine copper contraceptive)','58300 Insertion of intrauterine device (IUD) - Skyla',
			'58300 Insertion of intrauterine device (IUD) - Liletta (52mg)','J7297 - Levonorgestrel-releasing intrauterine contraceptive system (liletta), 52 mg'
		)

)
	select p.*, 
		f.PatientId, f.OrderProvider, f.OrderDate OrderDate, Facility, ic.InsuranceName, f.PrimInsuranceId
		, f.SDID
		--, doc.data DocData, doc.linkid
	into #with_codes
	from possible_codes p
		left join CpsWarehouse.cps_orders.Fact_all_orders f on p.OrderCodeID = f.OrderCodeID
		left join CpsWarehouse.cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = f.PrimInsuranceId
		--left join cpssql.CentricityPS.dbo.docdata doc on doc.sdid = f.SDID
	where f.OrderDate >= @startdate
		and f.OrderDate <= @enddate;
	

select * from #with_codes
go



/*incomplete
in-house medication but each sdid has multiple docdata rows. 
need to figure out how to clean it up*/
select doc.*,
	replace(
		replace(
			replace(
				replace(substring(data, CHARINDEX('medication administration', data), 300), '\par','')
			,'\fs20','')
		,'\b0','')
	,'\b','') Documentation
from #with_codes doc
left join cpssql.CentricityPS.dbo.docdata dd on dd.sdid = doc.SDID

go

/*all documents where "medication administration" form is used*/

declare @startdate date = '2020-07-01',
			@enddate date = '2020-12-31';
--drop table #all_med
select dd.data,doc.* 
into #all_med
from CpsWarehouse.cps_visits.Document doc
	left join cpssql.CentricityPS.dbo.docdata dd on dd.sdid = doc.SDID
where doc.ClinicalDateConverted >= @startdate
	and doc.ClinicalDateConverted <= @enddate
	and dd.data like '%medication administration%';

GO

/*get docdata where there is the words injection or medication
get the next 300 characters
remove rtf formats*/

select
	pp.PatientID,  df.ListName, m.ClinicalDateConverted Dates, m.Facility, ic.InsuranceName,
	sdid, 
	replace(
		replace(
			replace(
				replace(substring(data, CHARINDEX('medication administration', data), 300), '\par','')
			,'\fs20','')
		,'\b0','')
	,'\b','') Documentation
from #all_med m
	left join cps_all.PatientProfile pp on pp.PID = m.PID
	left join cps_all.DoctorFacility df on df.pvid = m.PubUser
	left join cps_all.PatientInsurance ins on ins.pid = pp.pid 
	left join cps_all.InsuranceCarriers ic on ic.InsuranceCarriersID = ins.PrimCarrierID
where m.sdid not in (select sdid from #with_codes)
and (data like '%injection%'
		or data like '%medication:%');

go







