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
                max(visit_date) over (
                    partition by visitor_id
                ) as last_visit
            from sessions
            where
                medium != 'organic'
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
    l.amount desc nulls last,
    t.visit_date,
    t.source,
    t.medium,
    t.campaign,
	t.visitor_id,
	l.lead_id,
    l.created_at,
    l.closing_reason,
    l.status_id
    