-- Raw ingestion layer for HM Land Registry's Price Paid Data CSV
CREATE DATABASE land_registry;

CREATE TABLE raw_price_paid (
    transaction_id  text,
    price           text,
    date_of_transfer text,
    postcode        text,
    property_type   text,
    old_new         text,
    duration        text,
    paon            text,
    saon            text,
    street          text,
    locality        text,
    town_city       text,
    district        text,
    county          text,
    ppd_category    text,
    record_status   text
);
