-- Applies the address cleaning functions to raw_price_paid and writes the
-- result to staging_price_paid_cleaned, ready for Splink record linkage.
DROP TABLE IF EXISTS staging_price_paid_cleaned;

CREATE TABLE staging_price_paid_cleaned AS
SELECT
    transaction_id,
    price::integer                                              AS price,
    date_of_transfer::date                                      AS date_of_transfer,
    property_type,
    old_new,
    duration,
    ppd_category,
    record_status,
    clean_postcode(postcode)                                    AS postcode_clean,
    NULLIF(clean_paon(paon), '')                                AS paon_clean,
    NULLIF(clean_address_text(saon), '')                        AS saon_clean,
    extract_flat_identifier(clean_address_text(saon))           AS flat_identifier,
    NULLIF(clean_address_text(street), '')                      AS street_clean,
    NULLIF(clean_address_text(locality), '')                    AS locality_clean,
    NULLIF(clean_address_text(town_city), '')                   AS town_city_clean,
    NULLIF(clean_address_text(district), '')                    AS district_clean,
    NULLIF(clean_address_text(county), '')                      AS county_clean
FROM raw_price_paid;

SET maintenance_work_mem = '512MB';

ALTER TABLE staging_price_paid_cleaned ADD PRIMARY KEY (transaction_id);
CREATE INDEX idx_staging_postcode ON staging_price_paid_cleaned (postcode_clean);
CREATE INDEX idx_staging_street   ON staging_price_paid_cleaned (street_clean);
CREATE INDEX idx_staging_paon     ON staging_price_paid_cleaned (paon_clean);

ANALYZE staging_price_paid_cleaned;
