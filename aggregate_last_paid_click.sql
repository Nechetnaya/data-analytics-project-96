--visit_date — дата визита
--utm_source / utm_medium / utm_campaign — метки пользователя
--visitors_count — количество визитов в этот день с этими метками
--total_cost — затраты на рекламу
--leads_count — количество лидов, которые оставили визиты, кликнувшие в этот день с этими метками
--purchases_count — количество успешно закрытых лидов (closing_reason = “Успешно реализовано” или status_code = 142)
--revenue — деньги с успешно закрытых лидов




with tab as (
    select
        visitor_id,
        visit_date,
        source,
        medium,
        campaign
    from
        (
            select
                visitor_id,
                visit_date,
                source,
                medium,
                campaign,
                max(s.visit_date) over (partition by visitor_id) as last_visit
            from sessions as s
            where medium in (
                    'cpc', 'cpm', 'cpa, ''youtube', 'cpp', 'tg', 'social'
                )
        ) as s
    where visit_date = last_visit
), 
last_paid_click as (
	select
	    t.visitor_id,
	    t.visit_date,
	    t.source as utm_source,
	    t.medium as utm_medium,
	    t.campaign as utm_campaign,
	    l.lead_id,
	    l.created_at,
	    l.amount,
	    l.closing_reason,
	    l.status_id
	from 
		tab as t left join 
		leads as l on t.visitor_id = l.visitor_id
	order by 
		amount desc nulls last,
		visit_date,
		utm_source, 
		utm_medium, 
		utm_campaign
),
ad_cost as (
	select 
		date(campaign_date) as campaign_date,
		utm_source,
		utm_medium,
		utm_campaign,
		sum(daily_spent) as total_cost
	from ya_ads ya 
	group by 1, 2, 3, 4
	union
	select 
		date(campaign_date) as campaign_date,
		utm_source,
		utm_medium,
		utm_campaign,
		sum(daily_spent) as total_cost
	from vk_ads 
	group by 1, 2, 3, 4
)
select 
	date(visit_date) as visit_date,
	lpc.utm_source,
	lpc.utm_medium,
	lpc.utm_campaign,
	avg(a.total_cost) as total_cost,
	count(visitor_id) as visitors_count,
	count(lead_id) as leads_count,
	count(lead_id) filter (where status_id = 142) as purchases_count,
    sum(amount) filter (where status_id = 142) as revenue
from last_paid_click as lpc left join
	ad_cost as a on 
		a.utm_medium = lpc.utm_medium
		and a.utm_source = lpc.utm_source
		and a.utm_campaign = lpc.utm_campaign
		and date(lpc.visit_date) = a.campaign_date
group by 1, 2, 3, 4
order by revenue desc nulls last,
	visit_date,
	visitors_count  desc,
	utm_source, utm_medium, utm_campaign


	





	
	