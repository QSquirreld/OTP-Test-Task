---Количество оплаченных кейсов по стратегиям---
/*
- "успешность" стратегии в кейсах
- Число уникальных кейсов, у которых был хотя бы один
положительный платёж в первые 7 дней.
*/

SELECT
    cc.strategy_name,
    COUNT(DISTINCT cc.case_id) AS paid_cases_7d
FROM collection_cases cc
JOIN payments p
    ON p.account_id = cc.account_id
    AND p.payment_dttm::date BETWEEN cc.start_date AND cc.start_date + 6
    AND p.payment_amount > 0
WHERE cc.start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28'
GROUP BY cc.strategy_name
ORDER BY cc.strategy_name;

---Сумма оплаченных кейсов по стратегиям---
/*
- "успешность" стратегии в деньгах
- Сколько денег принесла стратегия за первые 7 дней
*/

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
ORDER BY cc.strategy_name;