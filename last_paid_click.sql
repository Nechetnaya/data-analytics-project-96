/**visitor_id — уникальный человек на сайте
visit_date — время визита
utm_source / utm_medium / utm_campaign — метки c учетом модели атрибуции
lead_id — идентификатор лида, если пользователь сконвертился в лид после(во время) визита, NULL — если пользователь не оставил лид
created_at — время создания лида, NULL — если пользователь не оставил лид
amount — сумма лида (в деньгах), NULL — если пользователь не оставил лид
closing_reason — причина закрытия, NULL — если пользователь не оставил лид
status_id — код причины закрытия, NULL — если пользователь не оставил лид*/


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
                    'cpc', 'cpa', 'cpm', 'youtube', 'cpp', 'tg', 'social'
                )
--                or source in (
--                    'cpc', 'cpm', 'cpa', 'youtube', 'cpp', 'tg', 'social'
--                )
        ) as s
    where visit_date = last_visit
)
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

	





	
	