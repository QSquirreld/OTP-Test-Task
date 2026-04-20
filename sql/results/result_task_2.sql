---Итоговое решение---

WITH last_contacts AS (
    SELECT
        ce.case_id,
        MAX(ce.event_dttm) AS last_contact_dttm
    FROM contact_events ce
    JOIN collection_cases cc
        ON cc.case_id = ce.case_id
    WHERE cc.start_date BETWEEN DATE '2026-03-01' AND DATE '2026-03-31'
    GROUP BY ce.case_id
),
last_contact_details AS (
    SELECT
        lc.case_id,
        cc.account_id,
        cc.strategy_name,
        lc.last_contact_dttm,
        ce.channel AS last_channel,
        ce.contact_result AS last_contact_result
    FROM last_contacts lc
    JOIN collection_cases cc
        ON cc.case_id = lc.case_id
    JOIN contact_events ce
        ON ce.case_id = lc.case_id
        AND ce.event_dttm = lc.last_contact_dttm
)

SELECT
    lcd.case_id,
    lcd.account_id,
    lcd.strategy_name,
    lcd.last_contact_dttm,
    lcd.last_channel,
    lcd.last_contact_result,
    CASE -- в окне после последнего контакта есть положительный платёж
        WHEN COUNT(p.payment_id) > 0 THEN 1 
        ELSE 0
    END AS payment_in_5d_flag,
    SUM(p.payment_amount) AS payment_amount_5d
FROM last_contact_details lcd
LEFT JOIN payments p
    ON p.account_id = lcd.account_id
    AND p.payment_amount > 0
    AND p.payment_dttm::date BETWEEN lcd.last_contact_dttm::date AND lcd.last_contact_dttm::date + 4
GROUP BY
    lcd.case_id,
    lcd.account_id,
    lcd.strategy_name,
    lcd.last_contact_dttm,
    lcd.last_channel,
    lcd.last_contact_result
ORDER BY lcd.case_id;

/*
Последний контакт определял в два шага: сначала для каждого case_id находил максимальный event_dttm,
затем по паре case_id + last_contact_dttm возвращался в contact_events,
чтобы получить channel и contact_result именно для этой последней записи.

После этого по account_id проверял наличие положительных платежей в окне
от даты последнего контакта до +4 дней включительно и считал их суммарную сумму.
*/