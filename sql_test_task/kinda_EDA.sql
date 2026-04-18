---Таблицы---

SELECT * FROM accounts;

SELECT * FROM collection_cases;

SELECT * FROM contact_events;

SELECT * FROM payments;

---Категории---

SELECT DISTINCT strategy_name -- стратегия взыскания
FROM collection_cases;

SELECT DISTINCT dpd_bucket -- бакет просрочки
FROM collection_cases;

SELECT DISTINCT channel -- канал
FROM contact_events;

SELECT DISTINCT contact_result -- результат контакта
FROM contact_events;

---Количество+Категории---

SELECT
    strategy_name, -- стратегия взыскания
    COUNT(*) AS cnt
FROM collection_cases
GROUP BY strategy_name
ORDER BY cnt DESC;

SELECT
    dpd_bucket, -- бакет просрочки (1-30, 31-60, 61-90, 90+)
    COUNT(*) AS cnt
FROM collection_cases
GROUP BY dpd_bucket
ORDER BY dpd_bucket DESC;

SELECT
    channel, -- канал (call, sms, email)
    COUNT(*) AS cnt
FROM contact_events
GROUP BY channel;

SELECT
    contact_result, -- результат контакта (RPC, No answer, Wrong number, Promise)
    COUNT(*) AS cnt
FROM contact_events
GROUP BY contact_result
ORDER BY cnt DESC;

---Диапазоны---

SELECT
    MIN(start_date),
    MAX(start_date)
FROM collection_cases;

SELECT
    MIN(event_dttm),
    MAX(event_dttm)
FROM contact_events;

SELECT
    MIN(payment_dttm),
    MAX(payment_dttm)
FROM payments;

SELECT COUNT(*)
FROM collection_cases
WHERE start_date BETWEEN DATE '2026-02-01' AND DATE '2026-02-28';

---Пропуски (отсутствуют)---

SELECT COUNT(*)
FROM collection_cases cc
LEFT JOIN accounts a ON cc.account_id = a.account_id
WHERE a.account_id IS NULL;

SELECT COUNT(*)
FROM payments p
LEFT JOIN accounts a ON p.account_id = a.account_id
WHERE a.account_id IS NULL;

SELECT COUNT(*)
FROM contact_events ce
LEFT JOIN collection_cases cc ON ce.case_id = cc.case_id
WHERE cc.case_id IS NULL;

---Платежи---

SELECT
    MIN(payment_amount), -- диапазон
    MAX(payment_amount)
FROM payments;

SELECT COUNT(*) -- количество отрицательных
FROM payments
WHERE payment_amount <= 0;

---Дубли(вдруг)---

SELECT case_id, COUNT(*)
FROM collection_cases
GROUP BY case_id
HAVING COUNT(*) > 1;

SELECT account_id, COUNT(*)
FROM accounts
GROUP BY account_id
HAVING COUNT(*) > 1;