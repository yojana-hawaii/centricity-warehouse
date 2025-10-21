use CpsWarehouse
go
drop proc if exists cps_hchp.rpt_CaseManagerList;
go

create proc cps_hchp.rpt_CaseManagerList
as 
begin

	select [CBCM Case Manager], [HF Case Manager], [HF Housing Specialist], [Permanent Supportive Housing], [Community Integrated Services], Outreach, [Case Manager] BHCaseMngrNotInDropdown, HCHP NotInDropdown
	from (
		select ListName,  JobTitle , rowNum = ROW_NUMBER() over(partition by jobtitle order by listname )
		from cps_all.DoctorFacility
		where JobTitle in ('Case Manager','CBCM Case Manager','HCHP','Permanent Supportive Housing','HF Case Manager','HF Housing Specialist','Community Integrated Services','Outreach')
		and Inactive = 0
	) q
	pivot (
		max(listname)
		for jobtitle in ([Case Manager],[CBCM Case Manager],[Permanent Supportive Housing],[HF Case Manager],[HF Housing Specialist],[Community Integrated Services],[Outreach],[HCHP])
	) pvt
end

go
