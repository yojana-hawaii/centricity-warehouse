use CpsWarehouse
go

	declare @StartDate date = '2022-01-01', @EndDate date ='2022-12-31';
	drop table if exists #appt;
	select 
		c.AppointmentsID, ap.Facility, ap.ListName, ApptDateTime, ArrivedDate, 
		case when ArrivedDate  is not null and RegistrationCompletedDate is not null
			then datediff(MINUTE,ArrivedDate,RegistrationCompletedDate) 
		end RegistrationTime,  
		RegistrationCompletedDate, c.RegistrationCompletedBy, 
		case when ReadyForProviderDate  is not null and RegistrationCompletedDate is not null
			then datediff(MINUTE,RegistrationCompletedDate,ReadyForProviderDate) 
		end MATime, 
		ReadyForProviderDate, ReadyForProviderBy, 
		case when ReadyForProviderDate  is not null and CheckoutDate is not null and convert(date,ReadyForProviderDate) = convert(date,CheckoutDate)
			then datediff(MINUTE,ReadyForProviderDate,CheckoutDate) 
		end ProvTime,
		CheckoutDate,
		case when (ArrivedDate  is not null or RegistrationCompletedDate is not null) and CheckoutDate is not null and convert(date,ReadyForProviderDate) = convert(date,CheckoutDate)
			then datediff(MINUTE,isnull(ArrivedDate,RegistrationCompletedDate),CheckoutDate) 
		end TotalTime
	into #appt
	from cps_visits.ApptCycleType c
		left join cps_visits.Appointments ap on ap.AppointmentsID = c.AppointmentsID
	where convert(date, ApptDateTime) >= @StartDate
		and CONVERT(date,ApptDateTime) <= @EndDate
		and c.Canceled = 0;

	;with regtime as (
		select 
			Facility, 
			round(avg(RegistrationTime),2) AverageRegistration, Stdev(RegistrationTime) StDevRegistration, 
			min(RegistrationTime) MinRegistration, max(RegistrationTime) MaxRegistration
		from #appt
		where isnull(RegistrationTime ,0) > 1
		group by  Facility
	), matime as (
		select 
			Facility, 
			round(avg(MATime),2) AverageMA, Stdev(MATime) StDevMA, 
			min(MATime) MinMA, max(MATime) MaxMA
		from #appt
		where isnull(MATime ,0) > 1
		group by  Facility
	), provtime as (
		select 
			Facility, 
			round(avg(ProvTime),2) AverageProv, Stdev(ProvTime) StDevProv, 
			min(ProvTime) MinProv, max(ProvTime) MaxProv
		from #appt
		where isnull(ProvTime ,0) > 1
		group by  Facility
	), totalTime as (
		select 
			Facility, 
			round(avg(TotalTime),2) AverageTotal, Stdev(TotalTime) StDevTotal, 
			min(TotalTime) MinTotal, max(TotalTime) Maxtotal	
		from #appt
		where isnull(TotalTime ,0) > 1
		group by  Facility
	)
		select 
			p.Facility, 
			r.AverageRegistration, r.StDevRegistration,r.MinRegistration,r.MaxRegistration, 
			m.AverageMA, m.StDevMA,m.MinMA,m.MaxMA, 
			p.AverageProv, p.StDevProv, p.MinProv, p.MaxProv,
			t.AverageTotal, t.StDevTotal, t.MinTotal, t.Maxtotal
		from provtime p , matime m , regtime r, totalTime t
		where p.Facility = m.Facility
			and r.Facility = p.Facility
			and t.Facility = p.Facility

