COPY accounts
FROM 'C:\Users\QSquirrel\sql scripts\test-task\accounts.csv'
DELIMITER ','
CSV HEADER;

COPY collection_cases
FROM 'C:\Users\QSquirrel\sql scripts\test-task\collection_cases.csv'
DELIMITER ','
CSV HEADER;

COPY contact_events
FROM 'C:\Users\QSquirrel\sql scripts\test-task\contact_events.csv'
DELIMITER ','
CSV HEADER;

COPY payments
FROM 'C:\Users\QSquirrel\sql scripts\test-task\payments.csv'
DELIMITER ','
CSV HEADER;