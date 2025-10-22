
use CpsWarehouse
go

drop proc if exists cps_insurance.rpt_OhanaProviders_MissingDetails
go
 create proc cps_insurance.rpt_OhanaProviders_MissingDetails
 as
 begin

	drop table if exists #prov;
	select df.ListName Prov, df.NPI, n.OhanaSpecialty, n.NPIEnumerationDate, n.State, df.JobTitle, df.DoctorFacilityID
	into #prov
	from cps_all.DoctorFacility df
		left join dbo.NPIDetails n on df.DoctorFacilityID = n.DoctorFacilityID
	where Inactive = 0 and df.Billable = 1 
		and df.npi is not null and df.JobTitle not in  ('Case Manager', 'Therapist') ;-- and df.Specialty not in ('Behavioral Health');

	/* Get NPI registry link for provider
	select 
		prov, npi,  OhanaSpecialty, p.NPIEnumerationDate, 
		convert(varchar(10), DoctorFacilityID) + ',' + NPI, 
		'https://npiregistry.cms.hhs.gov/registry/search-results-table?number=' + NPI + '&addressType=ANY' Link
	from #prov p
	order by case when p.NPIEnumerationDate is null then 1 else 2 end, Prov;
	*/
	declare @missing_npi_count varchar(max)
	select @missing_npi_count = count(*)
	from #prov p
	where p.NPIEnumerationDate is null or State != 'HI';


	declare @prov varchar(max) = ''
	select @prov = @prov + convert(varchar(30), p.Prov) + case when p.NPIEnumerationDate is null then ' (Missing Specialty)' else ' (Wrong State ' + State + ')' end + '; '
		from #prov p
		where p.NPIEnumerationDate is null  or State != 'HI';

	set @prov = replace(@prov, ';', CHAR(13) )

	if @missing_npi_count > 0
	begin

	DECLARE @missing_npi_details NVARCHAR(MAX) = 'Hello X, 

This is auto-generated email. Below is list of Provders with NPI Problem. No NPI enumeration or state not Hawaii. More details in Josh folder. 
	
'
set @missing_npi_details = @missing_npi_details + @prov
set @missing_npi_details = @missing_npi_details + '
	
Thank you
me
	';

	--print @missing_npi_details

	end

	--if @missing_npi_count > 0
	--begin
	--	exec msdb.dbo.sp_send_dbmail
	--	@profile_name = 'dev-sql',
	--	@recipients = 'a@b.v',
	--	@copy_recipients = 'w@q.y',

	--	@body = @missing_npi_details,
	--	@subject = 'Auto-generated email: Missing Provider details for Ohana report';
	--end 

end
go
