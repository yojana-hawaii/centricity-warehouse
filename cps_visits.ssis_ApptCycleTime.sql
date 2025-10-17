 

use CpsWarehouse
go
drop table if exists cps_visits.ApptCycleType;
go
create table cps_visits.ApptCycleType (
	AppointmentsID int not null primary key,
	ApptDateTime  DateTime not null,
	Canceled tinyint not null,
	
	ApptCreatedDate datetime not null,
	LastMessageLeftDate datetime  null,
	LastPhoneIssueDate datetime  null,
	ConfirmedDate datetime  null,
	ArrivedDate datetime  null,
	RegistrationCompletedDate datetime  null,
	ReadyForProviderDate datetime  null,
	CheckoutDate datetime  null,
	CancellationDate datetime  null,

	ApptCreatedBy varchar(50) not null,
	LastMessageLeftBy varchar(50)  null,
	LastPhoneIssueBy varchar(50)  null,
	ConfirmedBy varchar(50)  null,
	ArrivedBy varchar(50)  null,
	RegistrationCompletedBy varchar(50)  null,
	ReadyForProviderBy varchar(50)  null,
	CheckoutBy varchar(50)  null,
	CancellationBy varchar(50)  null,

	TotalPhoneAttempt int not null,
	WellConfirmed tinyint not null,
	CancellationReason varchar(255) null

)
go

drop proc if exists cps_visits.ssis_ApptCycleTime;
go
create proc cps_visits.ssis_ApptCycleTime
as
begin 
	truncate table cps_visits.ApptCycleType;

	drop table if exists #aptStatus;
	;with app as (
		select --top 100 
			AppointmentsID, convert(datetime,ApptDate) + convert(datetime,StartTime) ApptDate, Duration,Canceled
		from CpsWarehouse.cps_visits.Appointments app
		where --app.ApptDate > '2022-07-01' and 
			app.apptdate < convert(date, getdate())
	)
	select 
		app.AppointmentsID,ApptDate, Canceled, Duration,
		arr.Functionname FunctionName, arr.TableName TableName, 
		Value1 Value1, Value2 Value2,
		Created Created, CreatedBy CreatedBy
	into #aptstatus
	from app
		inner join cpssql.centricityps.dbo.activitylog arr on arr.recordID = app.AppointmentsID 
	where TableName = 'Appointments'
		and FunctionName in ('Created Appointments','Change Appointment Status','Appointment Cancel');
	--	select * from #aptstatus
	
	drop table if exists #wellapp; 
	;with tmp_confirmed as (
		select AppointmentsID
		from #aptstatus
		where value1 = 'confirmed'
	), tmp_stat as (
		select u.AppointmentsID, a.value2
		from  tmp_confirmed u
			left join #aptstatus a on a.AppointmentsID = u.AppointmentsID and FunctionName = 'Change Appointment Status'
	)
		select AppointmentsID, 1 WellConfirmed
		into #wellapp
		from (
			select AppointmentsID,
				stuff((
					select ',' + Value2
					from tmp_stat t1
					where t1.AppointmentsID = t2.AppointmentsID
					for xml path('')
				),1,1,'') as val2
			from tmp_stat t2
			group by AppointmentsID
		) x
		where val2 not like '%confirmed%';

	--	select * from #wellapp

	drop table if exists #u;
	;with confirm as (
		select 
			AppointmentsID, Value2, Created, CreatedBy, 
			RowNum = ROW_NUMBER() over(partition by AppointmentsID order by created desc)
		from #aptstatus
		where Value2 = 'Confirmed' 
			and convert(date, Created) < convert(date,ApptDate) --confirmation usually not done on the day of appt
	), apptCreate as(
		select 
			AppointmentsID, ApptDate, Duration, Canceled, Created, CreatedBy, 
			RowNum = ROW_NUMBER() over(partition by AppointmentsID order by created desc)
		from #aptstatus
		where FunctionName = 'Created Appointments' --and convert(date, Created) < convert(date,ApptDate) -- Appt can be schedule on the day. SameDay Appt
	), checkout as(
		select 
			AppointmentsID, Created, CreatedBy, 
			RowNum = ROW_NUMBER() over(partition by AppointmentsID order by created desc)
		from #aptstatus
		where Value2 = 'Checked Out' and convert(date, Created) >= convert(date,ApptDate) --can only checkout on the day of. Does future check out count??
			and Canceled = 0
	), arrived as(
		select 
			AppointmentsID, Created, CreatedBy, 
			RowNum = ROW_NUMBER() over(partition by AppointmentsID order by created asc)
		from #aptstatus
		where Value2 = 'Arrived' and convert(date, Created) = convert(date,ApptDate) --can only arrive on the day of
	), regComplete as(
		select 
			AppointmentsID, Created, CreatedBy, 
			RowNum = ROW_NUMBER() over(partition by AppointmentsID order by created asc)
		from #aptstatus
		where Value2 = 'Registration Complete' and convert(date, Created) = convert(date,ApptDate) -- registration can only be completed on the day of
	), readyForProv as(
		select 
			AppointmentsID, Created, CreatedBy,  
			RowNum = ROW_NUMBER() over(partition by AppointmentsID order by created asc)
		from #aptstatus
		where Value2 = 'Ready for provider' and convert(date, Created) = convert(date,ApptDate) -- can only be ready from prov on the day of
	), leftMessage as(
		select 
			AppointmentsID, Created, CreatedBy, 
			RowNum = ROW_NUMBER() over(partition by AppointmentsID order by created desc)
		from #aptstatus
		where Value2 = 'Left Message' --and convert(date, Created) < convert(date,ApptDate) --seen instance of message left on the day of appt
			and isnull(value1,'') not in ('Arrived','Checked Out','Registration Complete','Ready for provider') -- no point leaving message after patient checked in
	),  phoneIssue as(
		select 
			AppointmentsID, Created, CreatedBy,
			RowNum = ROW_NUMBER() over(partition by AppointmentsID order by created desc)
		from #aptstatus
		where Value2 in ('Busy Number','No Answer','No Phone','Wrong Phone Number','Phone Disconnected') --and convert(date, Created) < convert(date,ApptDate) -- if patient no show, we may try to call??
			and isnull(Value1,'') not in ('Arrived','Checked Out','Registration Complete','Ready for provider') -- no point phone issue after patient checked in
	) , totalPhoneAttempt as (
		select AppointmentsID, count(*) TotalPhoneAttempt
		from (
			select AppointmentsID--,count(*) TotalPhoneAttemp
			from leftmessage
			union all
			select AppointmentsID
			from phoneIssue
		) x
		group by AppointmentsID
	), cancellation as(
		select 
			AppointmentsID, Created, CreatedBy,  value2,  
			RowNum = ROW_NUMBER() over(partition by AppointmentsID order by created desc)
		from #aptstatus
		where --Value2 in ('Deceased','Late Cancel','Left without being seen','No Show','Patient Cancelled Appt','Select a Reason . . .','Data Entry Error','Cancel/Facility Error','Provider Cancelled Appt')
				--and convert(date, Created) = ApptDate -- can only be ready from prov on the day of
			 Canceled = 1
	)
		
		select 
			a.AppointmentsID, a.ApptDate, a.Duration, a.Canceled, 
			a.Created ApptCreatedDate, a.CreatedBy ApptCreatedBy, 
			l.Created LastMessageLeftDate, l.CreatedBy LastMessageLeftBy,
			p.Created LastPhoneIssueDate, p.CreatedBy LastPhoneIssueBy,
			isnull(t.TotalPhoneAttempt,0) TotalPhoneAttempt,
			c.Created ConfirmedDate, c.CreatedBy ConfirmedBy, 
			case when c.CreatedBy = 'WELL' then 1 -- will not be triggered coz we looking at data up to yesterday. status should have been changed by now
				else isnull(w.WellConfirmed,0) 
			end WellConfirmed,
			ar.Created ArrivedDate, ar.CreatedBy ArrivedBy,
			reg.Created RegistrationCompletedDate, reg.CreatedBy RegistrationCompletedBy,
			prov.Created ReadyForProviderDate, prov.CreatedBy ReadyForProviderBy,
			ck.Created CheckoutDate, ck.CreatedBy CheckoutBy,
			can.Created CancellationDate, can.CreatedBy CancellationBy, can.Value2 CancellationReason
		into #u
		from apptCreate a
			left join confirm c on c.AppointmentsID = a.AppointmentsID and c.RowNum = 1
			left join #wellapp w on w.AppointmentsID = a.AppointmentsID
			left join leftMessage l on l.AppointmentsID = a.AppointmentsID and l.RowNum = 1
			left join phoneIssue p on p.AppointmentsID = a.AppointmentsID and p.RowNum = 1
			left join totalPhoneAttempt t on t.AppointmentsID = a.AppointmentsID
			left join arrived ar on ar.AppointmentsID = a.AppointmentsID and ar.RowNum = 1
			left join regComplete reg on reg.AppointmentsID = a.AppointmentsID and reg.RowNum = 1
			left join readyForProv prov on prov.AppointmentsID = a.AppointmentsID and prov.RowNum = 1
			left join checkout ck on ck.AppointmentsID = a.AppointmentsID and ck.RowNum = 1
			left join cancellation can on can.AppointmentsID = a.AppointmentsID and can.RowNum = 1;

	--exec tempdb.dbo.sp_help @objname = N'#u'

	insert into cps_visits.ApptCycleType(
		AppointmentsID, ApptDateTime,Canceled, 
		ApptCreatedDate, ApptCreatedBy, LastMessageLeftDate, LastMessageLeftBy, LastPhoneIssueDate, LastPhoneIssueBy, TotalPhoneAttempt,
		ConfirmedDate, ConfirmedBy, WellConfirmed,
		ArrivedDate, ArrivedBy, RegistrationCompletedDate, RegistrationCompletedBy, ReadyForProviderDate, ReadyForProviderBy,
		CheckoutDate, CheckoutBy,
		CancellationDate, CancellationBy, CancellationReason
	)
	select
		AppointmentsID, ApptDate,Canceled, 
		ApptCreatedDate, ApptCreatedBy, LastMessageLeftDate, LastMessageLeftBy, LastPhoneIssueDate, LastPhoneIssueBy, TotalPhoneAttempt,
		ConfirmedDate, ConfirmedBy, WellConfirmed,
		ArrivedDate, ArrivedBy, RegistrationCompletedDate, RegistrationCompletedBy, ReadyForProviderDate, ReadyForProviderBy,
		CheckoutDate, CheckoutBy,
		CancellationDate, CancellationBy, CancellationReason
	from #u

end

go
