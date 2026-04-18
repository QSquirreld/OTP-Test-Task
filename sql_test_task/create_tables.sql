CREATE TABLE accounts (
    account_id INT,
    principal_amount NUMERIC(10,2),
    product_type VARCHAR(50),
    region VARCHAR(50)
);

CREATE TABLE collection_cases (
    case_id INT,
    account_id INT,
    customer_id INT,
    start_date DATE,
    strategy_name VARCHAR(50),
    dpd_bucket VARCHAR(10)
);

CREATE TABLE contact_events (
    event_id INT,
    case_id INT,
    event_dttm TIMESTAMP,
    channel VARCHAR(20),
    contact_result VARCHAR(30),
    promise_to_pay_date DATE,
    promised_amount NUMERIC(10,2)
);

CREATE TABLE payments (
    payment_id INT,
    account_id INT,
    payment_dttm TIMESTAMP,
    payment_amount NUMERIC(10,2)
);