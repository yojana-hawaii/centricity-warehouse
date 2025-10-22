
use CpsWarehouse
go

drop proc if exists cps_insurance.rpt_Ohana_FlatFile;
go
create proc cps_insurance.rpt_Ohana_FlatFile
(
	@year int,
	@month varchar(3)
	--@quarter varchar(3)
)

as
begin
	

	--	declare @year int = 2021, @month varchar(3) = 2, @quarter varchar(3) = 'all'

	Set @month = case when @month = 'All' then null else @month end
	--Set @quarter = case when @quarter = 'All' then null else @quarter end
	--select @year, @month, @quarter

		--select
		--	'Member_Subscriber_ID|Member_CTRL_NUM|Member_FName|MemberLName|Member_SSN|Medicare_Num|Medicaid_Num|Birthdate|Sex|Provider_FName|Provider_LName|Provider_NPI|Provider_Specialty|Service_Date|Place_Of_Service|Service_Performed|Service_Result|Diagnosis1|Diagnosis2|Diagnosis3|Diagnosis4|Diagnosis5|Diagnosis6|Diagnosis7|Diagnosis8|Diagnosis8|Diagnosis10|Diagnosis11|Diagnosis12|Diagnosis13|Diagnosis14|Diagnosis15|Diagnosis16|Diagnosis17|Diagnosis18|Diagnosis19|Diagnosis20|Diagnosis21|Diagnosis22|Diagnosis23|Diagnosis24|Diagnosis25|ICD10_IND' col
		--union
		select 
			Member_Subscriber_ID + '||' + Member_FName  + '|' + Member_LName + '||||' + convert(varchar(8), Member_BirthDate, 112) + '|' + Member_Gender 
			 + '|' + Provider_FName + '|' + Provider_LName + '|' + Provider_NPI + '|' + Provider_Specialty
			 + '|' + convert(varchar(8),Service_Date, 112) + '|' + Place_Of_Service + '|' + Service_Performed + '|' + Service_Result
			 + '||||||||||||||||||||||||||' + 'y' 
		from cps_insurance.rpt_view_Ohana_FlatFile
		where year = @year
				and Month = isnull(@month, Month)
				--and Quarter = isnull(@quarter, Quarter)

end

go

