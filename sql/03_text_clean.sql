-- Using regex to clean postcode, address and PAON
CREATE OR REPLACE FUNCTION clean_postcode(input text)
RETURNS text AS $$
DECLARE
    compact text;
    len     int;
BEGIN
    compact := upper(regexp_replace(input, '\s+', '', 'g'));
    len := length(compact);
    IF len < 5 THEN
        RETURN NULL;
    END IF;
    RETURN substring(compact FROM 1 FOR len - 3) || ' ' || substring(compact FROM len - 2 FOR 3);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION clean_address_text(input text)
RETURNS text AS $$
DECLARE
    result text;
BEGIN
    result := upper(input);
    -- convert hyphens to spaces for welsh names
    result := replace(result, '-', ' ');
    result := regexp_replace(result, '[^A-Z0-9 ]', '', 'g');
    result := regexp_replace(result, '\s+', ' ', 'g');
    result := trim(result);
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION clean_paon(input text)
RETURNS text AS $$
DECLARE
    result text;
BEGIN
    result := upper(input);
    result := regexp_replace(result, '(\d)\s*-\s*(\d)', '\1<RANGE>\2', 'g');  -- now tolerates spaces
    result := replace(result, '-', ' ');
    result := regexp_replace(result, '[^A-Z0-9<> ]', '', 'g');
    result := replace(result, '<RANGE>', '-');
    result := regexp_replace(result, '\s+', ' ', 'g');
    result := trim(result);
    RETURN result;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION extract_flat_identifier(saon_cleaned text)
RETURNS text AS $$
DECLARE
    m text[];
BEGIN
    IF saon_cleaned IS NULL OR btrim(saon_cleaned) = '' THEN
        RETURN NULL;
    END IF;

    -- Two separate numbers, probably a range like "1-3": ambiguous, fall back to full string
    IF saon_cleaned ~ '\y[0-9]+\s+[0-9]+\y' THEN
        RETURN NULL;
    END IF;
    
    -- Parking, garages and storage reuse numbers that flats also use
    IF saon_cleaned ~ '\y(PARKING|GARAGE|STORE|STORAGE)\y' THEN
        RETURN NULL;
    END IF;

    -- keyword + identifier -> "FLAT 12A", "APARTMENT 3", "UNIT B"
    m := regexp_match(saon_cleaned, '(?:FLAT|APARTMENT|UNIT|SUITE)\s+([0-9]+[A-Z]?|[A-Z][0-9]*)\y');
    IF m IS NOT NULL THEN
        RETURN m[1];
    END IF;

    -- whole field is the identifier -> "12A", "A", "3"
    m := regexp_match(saon_cleaned, '^([0-9]+[A-Z]?|[A-Z][0-9]*)$');
    IF m IS NOT NULL THEN
        RETURN m[1];
    END IF;

    --trailing number after descriptive text -> "GROUND FLOOR FLAT 2" -> "2"
    m := regexp_match(saon_cleaned, '([0-9]+[A-Z]?)\y$');
    IF m IS NOT NULL THEN
        RETURN m[1];
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
