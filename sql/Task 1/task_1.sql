---Интервал по условию---
SELECT *
FROM collection_cases
WHERE start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28';

---Распределение кейсов по стратегиям(total_cases)---
SELECT
    strategy_name,
    COUNT(*) AS total_cases
FROM collection_cases
WHERE start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28'
GROUP BY strategy_name
ORDER BY total_cases DESC;

---Сколько кейсов с контактом(в интегрвале: start;start+6) contacted_cases_7d(770)---

SELECT -- контакты в первые 7 дней кейса
    cc.case_id,
    cc.start_date,
    ce.event_dttm
FROM collection_cases cc
LEFT JOIN contact_events ce
	ON ce.case_id = cc.case_id
	AND ce.event_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28';

SELECT -- количество уникальных контактов в первые 7 дней кейса
    COUNT(DISTINCT cc.case_id) AS contacted_cases_7d
FROM collection_cases cc
JOIN contact_events ce
    ON ce.case_id = cc.case_id
	AND ce.event_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28';

---Сколько кейсов оплаты(в интегрвале: start;start+6) paid_cases_7d (227)---

SELECT -- платежи в первые 7 дней кейса
    cc.case_id,
    cc.account_id,
    cc.start_date,
    p.payment_dttm,
    p.payment_amount
FROM collection_cases cc
JOIN payments p
    ON p.account_id = cc.account_id
    AND p.payment_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
    AND p.payment_amount > 0
WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28';

SELECT -- количество уникальных платежей в первые 7 дней кейса
    COUNT(DISTINCT cc.case_id) AS paid_cases_7d
FROM collection_cases cc
JOIN payments p
    ON p.account_id = cc.account_id
    AND p.payment_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
    AND p.payment_amount > 0
WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28';

---Собранная сумма(только платежи>0) для кейсов "моложе" 7 дней (collected_amount_7d)---

SELECT -- "Всего денег собрано"
    SUM(p.payment_amount) AS collected_amount_7d
FROM collection_cases cc
JOIN payments p
    ON p.account_id = cc.account_id
    AND p.payment_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
    AND p.payment_amount > 0
WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28';

---Средняя оплата за кейс (avg_collected_per_paid_case_7d)---
SELECT
    cc.strategy_name,
    SUM(p.payment_amount) / COUNT(DISTINCT cc.case_id) AS avg_collected_per_paid_case_7d
FROM collection_cases cc
JOIN payments p
    ON p.account_id = cc.account_id
    AND p.payment_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
    AND p.payment_amount > 0
WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28'
GROUP BY cc.strategy_name
ORDER BY cc.strategy_name;

---Собранная доля(в первые 7 дней) от долга collection_rate_7d---

SELECT
    cc.strategy_name,
    SUM(p.payment_amount) / SUM(a.principal_amount) AS collection_rate_7d
FROM collection_cases cc
JOIN accounts a
    ON a.account_id = cc.account_id
JOIN payments p
    ON p.account_id = cc.account_id
    AND p.payment_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
    AND p.payment_amount > 0
WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28'
GROUP BY cc.strategy_name
ORDER BY cc.strategy_name;

-- Некорректный(опасный) вариант: при нескольких платежах на один кейс
-- principal_amount ДУБЛИРУЕТСЯ после JOIN payments,
-- из-за чего collection_rate_7d может быть искажен.

WITH principal_stats AS (
    SELECT -- чтобы убрать дубли для principal_amount при JOIN с payments.
        cc.strategy_name,
        SUM(a.principal_amount) AS total_principal_amount
    FROM collection_cases cc
    JOIN accounts a
        ON a.account_id = cc.account_id
    WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28'
    GROUP BY cc.strategy_name
),
payment_stats AS (
    SELECT
        cc.strategy_name,
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
    ps.strategy_name,
    pms.collected_amount_7d / ps.total_principal_amount AS collection_rate_7d
FROM principal_stats ps
LEFT JOIN payment_stats pms
    ON pms.strategy_name = ps.strategy_name
ORDER BY ps.strategy_name;

---Итоговое решение---

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