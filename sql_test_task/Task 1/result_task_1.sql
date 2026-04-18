---Итоговое решение---

-- CREATE VIEW strategy_efficiency_7d AS | можно добавить view, чтобы использовать для отчётности или ветрине
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

/* Пояснение:
Сначала отдельно считаю по strategy_name базу кейсов за февраль 2026 года: общее число кейсов и сумму стартового долга.
Затем отдельно считаю число контактированных кейсов в первые 7 дней и отдельно — число оплаченных кейсов и сумму положительных платежей в том же окне.
После этого соединяю результаты по strategy_name и считаю производные метрики;
сумму долга считаю отдельно от платежей, чтобы не дублировался principal_amount при нескольких платежах на один кейс.
*/

/* Результат:
Стратегия late_stage показывает наилучшую эффективность (collection_rate_7d ≈ 5.3%)
за счёт более высокой конверсии в оплату и высокого среднего платежа.

Стратегия mixed демонстрирует стабильные результаты с близким уровнем сборов (~5.0%).

Стратегия soft_call показывает хорошую контактируемость,
но уступает по монетизации (ниже средний платеж и collection rate).

Стратегия sms_first является наименее эффективной:
ниже контактируемость, конверсия в оплату и средний платеж,
что приводит к минимальному collection_rate_7d (~3.6%).

Вывод: sms-first стратегия требует пересмотра,
тогда как late_stage и mixed выглядят наиболее эффективными.
*/