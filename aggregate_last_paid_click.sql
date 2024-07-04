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
            where
                medium in (
                    'cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social'
                )
--                or source in (
--                    'cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social'
--                )
        ) as s
    where visit_date = last_visit
),
ad_cost as (
	select 
		utm_source,
		utm_medium,
		utm_campaign,
		sum(daily_spent) as total_cost
	from ya_ads ya 
	group by 1, 2, 3
	union all
	select 
		utm_source,
		utm_medium,
		utm_campaign,
		sum(daily_spent) as total_cost
	from vk_ads va 
	group by 1, 2, 3
)
select
    date(t.visit_date) as visit_date,
    t.source as utm_source,
    t.medium as utm_medium,
    t.campaign as utm_campaign,
    count(t.visitor_id) as visitors_count,
    coalesce(a.total_cost, 0) as total_cost,
    count(l.lead_id) as leads_count,
    count(l.lead_id) filter (where closing_reason = 'Успешно реализовано' or status_id = 142) as purchases_count,
    sum(amount) filter (where closing_reason = 'Успешно реализовано' or status_id = 142) as revenue
from 
	tab as t left join 
	leads as l on t.visitor_id = l.visitor_id left join 
	ad_cost as a on t.source = a.utm_source
		and t.medium = a.utm_medium
		and t.campaign = a.utm_campaign
group by 1, 2, 3, 4, 6
order by 
	revenue desc nulls last,
	visit_date,
	visitors_count desc,
	utm_source, 
	utm_medium, 
	utm_campaign



