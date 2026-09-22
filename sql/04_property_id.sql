CREATE OR REPLACE FUNCTION street_key(street TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
    SELECT regexp_replace(
        regexp_replace(coalesce(street, '<NONE>'), '[^A-Z0-9]', '', 'g'),
        'S$', ''
    )
$$;

CREATE TABLE property_ids AS
SELECT
    postcode_clean,
    paon_clean,
    unit_key,
    street_key,
    row_number() OVER (ORDER BY postcode_clean, paon_clean, unit_key, street_key) AS property_id
FROM (
    SELECT DISTINCT
        coalesce(postcode_clean, '<NONE>') AS postcode_clean,
        coalesce(paon_clean, '<NONE>') AS paon_clean,
        coalesce(flat_identifier, saon_clean, '<NONE>') AS unit_key,
        street_key(street_clean) AS street_key
    FROM staging_price_paid_cleaned
    WHERE NOT (property_type IN ('F', 'O') AND saon_clean IS NULL)
) keys;

CREATE TABLE transaction_property_ids AS
SELECT
    t.transaction_id,
    p.property_id
FROM staging_price_paid_cleaned t
JOIN property_ids p
  ON coalesce(t.postcode_clean, '<NONE>') = p.postcode_clean
 AND coalesce(t.paon_clean, '<NONE>') = p.paon_clean
 AND coalesce(t.flat_identifier, t.saon_clean, '<NONE>') = p.unit_key
 AND street_key(t.street_clean) = p.street_key
WHERE NOT (t.property_type IN ('F', 'O') AND t.saon_clean IS NULL);

-- Unit unknown table
CREATE TABLE transaction_unit_unknown AS
SELECT transaction_id
FROM staging_price_paid_cleaned
WHERE property_type IN ('F', 'O') AND saon_clean IS NULL;
