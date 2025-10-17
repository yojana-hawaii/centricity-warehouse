
Go
use CpsWarehouse
go

drop function if exists fxn.ConvertObsHdidIntoDynamicPivot ;
go
create function fxn.ConvertObsHdidIntoDynamicPivot ( 
	@comma_separated_hdid nvarchar(max),
	@StartDate date = null,
	@EndDate date = null
)
returns nvarchar(max) 
as
begin

--declare @comma_separated_hdid nvarchar(max), @StartDate date = '2019-01-01', @EndDate date = '2019-01-02' ;

--/*all HDID in vital sign form as of 2-26-2019*/
--set @comma_separated_hdid = '4277,5686,148026,2612,2788,22346,18332,2886,2884,53,2885,2883,54,2647,1018,276050,9266,395186,
--	48469,5346,96,3096,55,5348,3094,2688,539801,132035,2488,7193,7194,2871,2869,2867,2865,407468,407461,407463,
--	2540,2709,2779,277295,6459,6460,2173,216915,5928,360020,5927,9356,7212,131331,2743,406564,17232,392784,407469,
--	407462,407464,56,4747,2972,57,2870,2868,2866,2864,4541,6814,60,4254,2641,396500,200095,200094,6431,5716,5717,
--	6432,2568,12857,61,5347,3095,29139';

/*convert date to varchar for dynamic sql*/
declare @StartDate1 nvarchar(10) = convert(nvarchar(10), @StartDate );
declare @EndDate1 nvarchar(10) = convert(nvarchar(10), @EndDate );

declare @sql nvarchar(max), @main_columns nvarchar(max), @pivot_columns nvarchar(max);

/*split and put in temp table*/
declare @hdid table ( HDID int)
insert into @hdid
select convert(int,fxn.RemoveNonAlphaNumericCharacters(Item) ) HDID
from fxn.SplitStrings(@comma_separated_hdid, ',');

--select * from @hdid

/*get obsterm from obshead table*/
declare @obs_terms table (hdid int, obsTerm nvarchar(50) )
insert into @obs_terms
select h.HDID, lower(oh.Name) Obsterm 
from cpssql.CentricityPS.dbo.OBSHEAD oh
	inner join @hdid h on h.HDID = oh.hdid;

--select * from @obs_terms

/*define main columns by renaming hdid with obsterm*/
set @main_columns = N'';
select @main_columns += N', p.' + QUOTENAME(HDID) + N' as ' + QUOTENAME( Obsterm )
	from
	(
		select p.HDID, p.Obsterm from @obs_terms as p
	) as x;

--select @main_columns


/*remove first 2 characters, comma and space*/
select @main_columns = right(@main_columns, len(@main_columns) - 2);
--select @main_columns


/*define pivot columns with just hdid for pviot aggregate*/
set @pivot_columns = N'';
select @pivot_columns += N', ' + QUOTENAME(HDID)
	from
	(
		select p.HDID, p.Obsterm from @obs_terms as p
	) as x;
--select @pivot_columns

/*remove leading comma*/
select @pivot_columns = right(@pivot_columns, len(@pivot_columns) - 2);

--select @pivot_columns

--vitals form
set @sql = N'

select PID, SDID, XID,  ' + @main_columns + '
into ##dynamic_temp_table
from
(
	select obs.hdid HDID,obs.PID PID, obs.SDID SDID, obs.XID XID, obs.OBSVALUE Obsvalue
	from cpssql.CentricityPS.dbo.obs
	where 
		obs.hdid in ('+@comma_separated_hdid +')
		and convert(date,db_create_date) >= ''' +  @StartDate1 + '''
		and convert(date,db_create_date) <= ''' +  @EndDate1 + '''
)
as q
pivot
(
	max(obsvalue)
	for hdid in (' + @pivot_columns + ')
)
as p

'
--print @sql

--exec sP_executesql @sql
return @sql

end

go