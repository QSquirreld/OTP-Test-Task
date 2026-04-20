WITH base_cases AS (
    SELECT
        cc.case_id,
        cc.account_id,
        cc.strategy_name,
        cc.start_date,
        date_trunc('week', cc.start_date) AS week_start
    FROM collection_cases cc
    WHERE cc.start_date BETWEEN DATE '2026-01-01' AND DATE '2026-03-31'
),

total_stats AS (
    SELECT
        bc.week_start,
        bc.strategy_name,
        COUNT(*) AS total_cases
    FROM base_cases bc
    GROUP BY
        bc.week_start,
        bc.strategy_name
),

rpc_stats AS (
    SELECT
        bc.week_start,
        bc.strategy_name,
        COUNT(DISTINCT bc.case_id) AS rpc_cases_7d
    FROM base_cases bc
    JOIN contact_events ce
        ON ce.case_id = bc.case_id
        AND ce.contact_result = 'RPC'
        AND ce.event_dttm::date BETWEEN bc.start_date AND bc.start_date + 6
    GROUP BY
        bc.week_start,
        bc.strategy_name
),

promise_stats AS (
    SELECT
        bc.week_start,
        bc.strategy_name,
        COUNT(DISTINCT bc.case_id) AS promise_cases_7d
    FROM base_cases bc
    JOIN contact_events ce
        ON ce.case_id = bc.case_id
        AND (ce.promised_amount > 0 OR ce.promise_to_pay_date IS NOT NULL)
        AND ce.event_dttm::date BETWEEN bc.start_date AND bc.start_date + 6
    GROUP BY
        bc.week_start,
        bc.strategy_name
),

first_promises AS (
    SELECT
        bc.case_id,
        MIN(ce.event_dttm) AS first_promise_dttm
    FROM base_cases bc
    JOIN contact_events ce
        ON ce.case_id = bc.case_id
        AND (
            ce.promised_amount > 0
            OR ce.promise_to_pay_date IS NOT NULL
       )
       AND ce.event_dttm::date BETWEEN bc.start_date AND bc.start_date + 6
    GROUP BY bc.case_id
),

first_promise_details AS (
    SELECT
        fp.case_id,
        bc.account_id,
        bc.week_start,
        bc.strategy_name,
        ce.promise_to_pay_date,
        ce.promised_amount
    FROM first_promises fp
    JOIN base_cases bc
        ON bc.case_id = fp.case_id
    JOIN contact_events ce
        ON ce.case_id = fp.case_id
        AND ce.event_dttm = fp.first_promise_dttm
),

kept_promise_stats AS (
    SELECT
        t.week_start,
        t.strategy_name,
        COUNT(*) AS kept_promise_cases
    FROM (
        SELECT
            fpd.case_id,
            fpd.week_start,
            fpd.strategy_name,
            fpd.promised_amount,
            fpd.promise_to_pay_date,
            SUM(p.payment_amount) AS paid_until_promise_date
        FROM first_promise_details fpd
        LEFT JOIN payments p
            ON p.account_id = fpd.account_id
            AND p.payment_amount > 0
            AND p.payment_dttm::date <= fpd.promise_to_pay_date
        GROUP BY
            fpd.case_id,
            fpd.week_start,
            fpd.strategy_name,
            fpd.promised_amount,
            fpd.promise_to_pay_date
    ) t
    WHERE t.paid_until_promise_date >= t.promised_amount
    GROUP BY
        t.week_start,
        t.strategy_name
),

recovery_stats AS (
    SELECT
        bc.week_start,
        bc.strategy_name,
        SUM(p.payment_amount) AS recovery_amount_14d
    FROM base_cases bc
    JOIN payments p
        ON p.account_id = bc.account_id
        AND p.payment_amount > 0
        AND p.payment_dttm::date BETWEEN bc.start_date AND bc.start_date + 13
    GROUP BY
        bc.week_start,
        bc.strategy_name
)

SELECT
    ts.week_start,
    ts.strategy_name,
    ts.total_cases,
    rs.rpc_cases_7d,
    ps.promise_cases_7d,
    kps.kept_promise_cases,
    rcs.recovery_amount_14d,
    rs.rpc_cases_7d::numeric / NULLIF(ts.total_cases, 0) AS rpc_rate_7d, -- расчёт rate'ов
    ps.promise_cases_7d::numeric / NULLIF(rs.rpc_cases_7d, 0) AS promise_rate_from_rpc,
    kps.kept_promise_cases::numeric / NULLIF(ps.promise_cases_7d, 0) AS kept_promise_rate
FROM total_stats ts
LEFT JOIN rpc_stats rs
    ON rs.week_start = ts.week_start
    AND rs.strategy_name = ts.strategy_name
LEFT JOIN promise_stats ps
    ON ps.week_start = ts.week_start
    AND ps.strategy_name = ts.strategy_name
LEFT JOIN kept_promise_stats kps
    ON kps.week_start = ts.week_start
    AND kps.strategy_name = ts.strategy_name
LEFT JOIN recovery_stats rcs
    ON rcs.week_start = ts.week_start
    AND rcs.strategy_name = ts.strategy_name
ORDER BY
    ts.week_start,
    ts.strategy_name;