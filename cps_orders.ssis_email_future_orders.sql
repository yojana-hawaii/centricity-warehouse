
use CpsWarehouse
go

drop proc if exists cps_orders.ssis_email_future_orders;
go

create proc cps_orders.ssis_email_future_orders
as
begin

declare @today date = convert(date, getdate() );
declare @overOneYear date = dateadd(year, 1, @today	 );
declare @overTwoYear date = dateadd(year, 2, @today	 );


drop table if exists #future_orders;
select df.listname Providers, pp.PatientID, o.description OrderName, convert(date, o.orderdate) OrderDate, pp.Name, o.status, o.xid
into #future_orders
from cpssql.centricityps.dbo.orders o
left join CpsWarehouse.cps_all.DoctorFacility df on df.PVID = o.pubuser
left join CpsWarehouse.cps_all.PatientProfile pp on pp.pid = o.pid
where o.orderdate > @overTwoYear
	and o.status != 'x'
	and o.xid = 1000000000000000000;



/*count number if future orders*/
declare @future_count int 
select @future_count = count(*)
from #future_orders;




--https://www.mssqltips.com/sqlservertip/6914/beautify-html-tables-email-sql-database-mail/

if @future_count > 0
begin

declare @body varchar(max) = '
<html>
<head>
	<style>
		#g {color: green; }
		#r {color: red; }
		#odd {backgroud-color: lightgrey; }
	</style>
</head>';


declare @recipeints varchar(256) = 'someone@a.b';
declare @cc varchar(256) = 'x@y.z';
declare @subject varchar(128) = 'Auto-generated email: way in the future orders'

/*html table*/
declare @xml nvarchar(max);
set @xml = CAST(
	(
		select 
			f.Providers as 'td', '' , PatientID as 'td', '' , OrderName as 'td', '', 
			case when OrderDate >= @overTwoYear then 'zr' + cast(OrderDate as varchar(30))
				else 'zg' + cast(OrderDate as varchar(30))
				end as 'td' 
		from #future_orders f
		order by OrderDate
		for xml path ('tr'), elements
	) as nvarchar(max)
)

set @xml = replace(@xml, '<td>zr', '<td id = "r">');
set @xml = replace(@xml, '<td>zg', '<td id = "g">');



declare @s varchar(max), @pos int, @i int = 0, @ts varchar(max);
select @s = '', @pos = charindex('<tr>', @xml, 4);

while (@pos > 0)
begin
	set @i += 1;
	set @ts = substring(@xml, 1, @pos-1)

	if (@i % 2 = 1)
		set @ts = REPLACE(@ts, '<tr>', '<tr id = "odd">');

	set @s += @ts;

	set @xml = substring(@xml, @pos, len(@xml));
	set @pos = CHARINDEX('<tr>', @xml, 4);

end
--handling last piece
set @i += 1;
set @ts = @xml;

if (@i % 2 = 1)
	set @ts = replace(@ts, '<ts>', '<tr id = "odd">');

set @s += @ts;

set @body += '
	<body> 
		<H3>
			This is auto-generated email.
		</H3>
		<p>
			Orders more than 1 year in future. Red is orders more than 2 years into future
		</p>
		<table border=1>
			<tr>
				<th>Provider</th>
				<th>Patient ID</th>
				<th>Order</th>
				<th>Order Date</th>
			</tr>'
			+ @s + 
		'</table> '
		+ '
						
<br/><br/>				
Thank you
<br/>
me
	
	</body> 
<html>
';

	--exec msdb.dbo.sp_send_dbmail
	--	@profile_name = 'sql-profile',
	--	@recipients = @recipeints,
	--	@copy_recipients = @cc,

	--	@body = @body,
	--	@subject = @subject,
	--	@body_format = 'HTML';
end



end

go
