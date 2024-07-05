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
                row_number() over (
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
        l.lead_id,
        l.amount,
        l.status_id
    from
        tab as t left join
        leads as l
        on
            t.visitor_id = l.visitor_id
            and t.visit_date < l.created_at
    order by
        l.amount desc nulls last,
        t.visit_date asc,
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
    group by
        date(campaign_date),
        utm_source,
        utm_medium,
        utm_campaign
    union
    select
        date(campaign_date) as campaign_date,
        utm_source,
        utm_medium,
        utm_campaign,
        sum(daily_spent) as total_cost
    from vk_ads
    group by
        date(campaign_date),
        utm_source,
        utm_medium,
        utm_campaign
),

s_h as (
    select
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        a.total_cost::INT,
        date(lpc.visit_date) as visit_date,
        count(lpc.visitor_id) as visitors_count,
        count(lpc.lead_id) as leads_count,
        count(lpc.lead_id) filter (
            where lpc.status_id = 142
        ) as purchases_count,
        sum(lpc.amount) filter (where lpc.status_id = 142) as revenue
    from last_paid_click as lpc left join
        ad_cost as a
        on
            lpc.utm_medium = a.utm_medium
            and lpc.utm_source = a.utm_source
            and lpc.utm_campaign = a.utm_campaign
            and date(lpc.visit_date) = a.campaign_date
    group by
        date(lpc.visit_date),
        lpc.utm_source,
        lpc.utm_medium,
        lpc.utm_campaign,
        a.total_cost::INT
)

select
    visit_date,
    visitors_count,
    utm_source,
    utm_medium,
    utm_campaign,
    total_cost,
    leads_count,
    purchases_count,
    revenue
from s_h
order by
    revenue desc nulls last,
    visit_date asc,
    visitors_count desc,
    utm_source asc,
    utm_medium asc,
    utm_campaign asc
