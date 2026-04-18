WITH base_stats AS (
    SELECT
        cc.strategy_name,
        COUNT(*) AS total_cases,
        SUM(a.principal_amount) AS total_principal_amount
    FROM collection_cases cc
    JOIN accounts a
        ON a.account_id = cc.account_id
    WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28'
    GROUP BY cc.strategy_name
),

contact_stats AS (
    SELECT
        cc.strategy_name,
        COUNT(DISTINCT cc.case_id) AS contacted_cases_7d
    FROM collection_cases cc
    JOIN contact_events ce
        ON ce.case_id = cc.case_id
        AND ce.event_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
    WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28'
    GROUP BY cc.strategy_name
),

payment_stats AS (
    SELECT
        cc.strategy_name,
        COUNT(DISTINCT cc.case_id) AS paid_cases_7d,
        SUM(p.payment_amount) AS collected_amount_7d
    FROM collection_cases cc
    JOIN payments p
        ON p.account_id = cc.account_id
        AND p.payment_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
        AND p.payment_amount > 0
    WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28'
    GROUP BY cc.strategy_name
)

SELECT
    b.strategy_name,
    b.total_cases,
    c.contacted_cases_7d,
    p.paid_cases_7d,
    p.collected_amount_7d,
    p.collected_amount_7d / NULLIF(p.paid_cases_7d, 0) AS avg_collected_per_paid_case_7d,
    p.collected_amount_7d / NULLIF(b.total_principal_amount, 0) AS collection_rate_7d
FROM base_stats b
LEFT JOIN contact_stats c
    ON c.strategy_name = b.strategy_name
LEFT JOIN payment_stats p
    ON p.strategy_name = b.strategy_name
ORDER BY b.strategy_name;