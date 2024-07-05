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
                row_number () over (
                	partition by visitor_id
                	order by visit_date desc
                	) as last_visit
            from sessions
            where medium != 'organic'
        ) as s
    where last_visit = 1
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
        sum(daily_spent) as total_cost
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
    count(visitor_id) as visitors_count,
    lpc.utm_source,
    lpc.utm_medium,
    lpc.utm_campaign,
    a.total_cost::INT,
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
group by 1, 3, 4, 5, 6
order by
    revenue desc nulls last,
    visit_date asc,
    visitors_count desc,
    utm_source asc, utm_medium asc, utm_campaign asc
    