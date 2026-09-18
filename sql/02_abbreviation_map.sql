-- Maps common address abbreviations for downstream normalization
CREATE TABLE address_abbreviation_map (
    abbrev     text PRIMARY KEY,
    expansion  text NOT NULL
);

INSERT INTO address_abbreviation_map (abbrev, expansion) VALUES
    ('RD',  'ROAD'),
    ('ST',  'STREET'),
    ('AVE', 'AVENUE'),
    ('FLT', 'FLAT'),
    ('APT', 'APARTMENT');
