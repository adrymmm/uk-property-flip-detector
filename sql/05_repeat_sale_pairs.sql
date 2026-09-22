CREATE TABLE repeat_sale_pairs AS
SELECT
    property_id,
    prev_transaction_id,
    transaction_id AS curr_transaction_id,
    prev_date AS prev_date_of_transfer,
    date_of_transfer AS curr_date_of_transfer,
    prev_price,
    price AS curr_price,
    prev_ppd_category,
    ppd_category AS curr_ppd_category,
    prev_duration,
    duration AS curr_duration,
    (date_of_transfer - prev_date) AS holding_period_days,
    ln(price::numeric / prev_price) AS log_price_ratio
FROM (
    SELECT
        t.property_id,
        s.transaction_id,
        s.date_of_transfer,
        s.price,
        s.ppd_category,
        s.duration,
        LAG(s.transaction_id) OVER w AS prev_transaction_id,
        LAG(s.date_of_transfer) OVER w AS prev_date,
        LAG(s.price) OVER w AS prev_price,
        LAG(s.ppd_category) OVER w AS prev_ppd_category,
        LAG(s.duration) OVER w AS prev_duration
    FROM transaction_property_ids t
    JOIN staging_price_paid_cleaned s ON s.transaction_id = t.transaction_id
    WINDOW w AS (PARTITION BY t.property_id ORDER BY s.date_of_transfer, s.transaction_id)
) paired
WHERE prev_transaction_id IS NOT NULL;


CREATE VIEW repeat_sale_pairs_regression AS
SELECT *
FROM repeat_sale_pairs
WHERE holding_period_days > 0
  AND prev_ppd_category = 'A'
  AND curr_ppd_category = 'A'
  AND prev_duration = curr_duration;
