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
                max(visit_date) over (partition by visitor_id) as last_visit
            from sessions
            where medium != 'organic'
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
        lead_id,
        l.amount,
        l.status_id
    from
        tab as t left join
        leads as l
        on
            t.visitor_id = l.visitor_id
            and t.visit_date < l.created_at
    order by
        amount desc nulls last,
        visit_date asc,
        utm_source asc,
        utm_medium asc,
        utm_campaign asc
),
ad_cost as (
    select
        date(campaign_date) as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        round(sum(daily_spent)) as total_cost
    from ya_ads
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
    ad_cost as a
    on
        lpc.utm_medium = a.utm_medium
        and lpc.utm_source = a.utm_source
        and lpc.utm_campaign = a.utm_campaign
        and date(lpc.visit_date) = a.campaign_date
group by 1, 2, 3, 4
order by
    revenue desc nulls last,
    visit_date asc,
    visitors_count desc,
    utm_source asc, utm_medium asc, utm_campaign asc