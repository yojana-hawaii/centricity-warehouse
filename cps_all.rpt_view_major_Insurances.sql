

use CpsWarehouse
go

drop view if exists cps_all.rpt_view_major_Insurances
go
create view cps_all.rpt_view_major_Insurances
as
select  distinct ic.Classify_Major_Insurance 
from cps_all.InsuranceCarriers ic
union 
select 'All'

go
