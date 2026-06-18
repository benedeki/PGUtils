/*
 * Copyright 2026 David Benedeki, All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

CREATE OR REPLACE FUNCTION pgarray.is_unique(
    IN  i_array             ANYARRAY,
    IN  i_nulls_distinct    BOOLEAN DEFAULT false,
    OUT is_unique           BOOLEAN
)
-------------------------------------------------------------------------------
--
-- Function: pgarray.is_unique(2)
-- Version:  0.1.0
--
--      Checks if the array contains only unique values
--
-- Parameters:
--
--      i_array             - The array of any type to check
--      i_nulls_distinct    - if TRUE, NULL values are treated as distinct, otherwise they are considered duplicates if
--                            appearing more than once in the array. The default value is FALSE.
--
-- Returns:
--      is_unique           - TRUE if the array contains only unique values, FALSE if the array has at least one duplicate value
--
-------------------------------------------------------------------------------
RETURNS BOOLEAN AS $$
DECLARE
    _cardinality    INTEGER;
    _distinct_count INTEGER;
    _null_count     INTEGER;
BEGIN
    _cardinality = cardinality(i_array);

    SELECT
        count(*) FILTER (WHERE x IS NULL),
        count(DISTINCT x)
    FROM unnest(i_array) x
    INTO _null_count, _distinct_count;

    IF i_nulls_distinct THEN
        is_unique := _cardinality = _distinct_count + _null_count;
    ELSE
        is_unique := (_cardinality = _distinct_count + _null_count) AND
            (_null_count <= 1);
    END IF;

    RETURN;
END
$$ LANGUAGE plpgsql IMMUTABLE SECURITY INVOKER;

ALTER FUNCTION pgarray.is_unique (ANYARRAY, BOOLEAN) OWNER TO pgutils_owner;

GRANT EXECUTE ON FUNCTION pgarray.is_unique (ANYARRAY, BOOLEAN) TO public;
