go 
use CpsWarehouse
go

drop proc if exists cps_imm.rpt_email_duplicate_in_srx;
go
create proc cps_imm.rpt_email_duplicate_in_srx
as
begin
		drop table if exists #duplicates;
	select 
		pp.name,s.patientid PatientID, lotno LotNo, rxname RxName, RxSRXID barcode, 
		convert(date, shotdate) admindate,spusername SpUsername, count(*) total
	into #duplicates
	FROM cpssql.[SRX_KPHC].[dbo].[Shot] s
		left join cps_all.PatientProfile pp on pp.PatientID = s.patientid
	where s.shotdate >= '2022-07-01'-- convert(date, getdate() )
		and pp.TestPatient = 0
	group by s.patientid, lotno, convert(date, shotdate), rxname,spusername, pp.Name, RxSRXID
	having count(*) > 1

	drop table if exists #dups_with_date;
	;with v as (
		select eDate eDate, UserID UserID, ReqString Reqstring
		from cpssql.[SRX_KPHC].[dbo].WSLOG
		where reqstring like '%"query":"false"%'
	)
		select 
			u.name,  u.PatientID, u.LotNo, u.RxName, convert(date,v.eDate)admindate, v.UserID SpUsername, u.barcode, u.total, v.eDate
		into #dups_with_date
		from #duplicates u
			inner join v on Reqstring like '%' + u.barcode + '%'
				and Reqstring like '%' + u.PatientID + '%'
				--and convert(date, edate) = u.admindate

	declare @dup_count varchar(max);

	select @dup_count = count(*) 
	from #dups_with_date
	where admindate = convert(date, getdate())

	if @dup_count > 0
	begin
		declare @email_body varchar(max) = 'Hello all,
		</br></br>
This is auto-generated email. Below is the list of duplicates in SRX.

';
		declare @xml varchar(max);

		set @xml = cast
				(
						(
							select 
								PatientID as 'td','', lotNo as 'td','', 
								RxName as 'td','', admindate as 'td','', 
								SpUsername as 'td','', barcode as 'td','', 
								total as 'td','', eDate as 'td','' 
							from #dups_with_date
							where admindate = convert(date, getdate())
							order by eDate desc
							for xml path('tr'), elements
						) as nvarchar(max)
				);
		set @email_body = @email_body + '
					<html><body><H3>Duplicates for today.</H3>
					<table border = 1>
					<tr>
					<th> Patient ID </th>
					<th> Lot No </th>
					<th> Rxname </th>
					<th> AdminDate </th>
					<th> User </th>
					<th> Barcode </th>
					<th> Total </th>
					<th> Log Date </th></tr>
				'
		set @email_body = @email_body + @xml + '</table></body></html>' + '
		</br></br>
Details since 7-1-2022 in Immunization report folder.
</br></br>
Thank you </br>
Me
		'
		--print @email_body
		
		declare @time int
		select @time = datepart(hour, getdate() )
		--if @time < 19 and @time > 6
		--begin
			--exec msdb.dbo.sp_send_dbmail
			--	@profile_name = 'prof-sql',
			--	@recipients = 'a@b.b',
			--	@copy_recipients = 'e@f.g; h@i.j',
			--	@body_format = 'HTML',
			--	@body = @email_body,
			--	@subject = 'Auto-generated email: Duplicate SRX for the day'; 
		--end
	end

	select * from #dups_with_date
	order by LotNo, name--admindate desc, name, edate desc	

end

go
