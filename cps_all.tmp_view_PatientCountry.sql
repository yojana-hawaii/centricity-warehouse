
use CpsWarehouse
go

DROP view if exists cps_all.tmp_view_PatientCountry;
go
create view cps_all.tmp_view_PatientCountry
as
WITH lang AS
(
	
	select 
		convert(int,chc.TableKey) PatientProfileid,
		max(case when chc.FieldId = 2 then item.ItemText end) BirthPlace,
		max(case when chc.FieldId = 3 then chc.Value end) OtherBirthPlace,
		max(case when chc.FieldId = 4 then chc.Value end) DateOfEntered
		--field.*
	from cpssql.Centricityps.dbo.cusCHCFieldValue chc
		left join cpssql.Centricityps.dbo.cusCHCField field on field.id = chc.fieldid
		left join cpssql.Centricityps.dbo.cusCHCFieldItem item on item.ItemValue = chc.value
	where chc.fieldid in (2,3,4)
		--and chc.TableKey = '12001425'
	group by chc.TableKey
)
	-- clean up pivotted data
	select 
		 t2.PatientProfileID,
		(CASE WHEN t2.OtherBirthPlace != '' then t2.OtherBirthPlace
		ELSE t2.BirthPlace
		END) BirthPlace,
		(CASE WHEN t2.DateOfEntered = '1800-01-01' THEN ''
			ELSE t2.DateOfEntered
			END) AS 'DateOf Entry'
	from lang t2;

go
