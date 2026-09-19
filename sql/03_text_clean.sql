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
