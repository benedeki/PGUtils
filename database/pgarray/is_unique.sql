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

CREATE OR REPLACE FUNCTION pgarray.is_unique (
       i_array              ANYARRAY,
       i_nulls_distinct     BOOLEAN DEFAULT false
)
-------------------------------------------------------------------------------
--
-- Function: utils.is_unique(2)
-- Version:  0.1.0
--
--      Checks if the array contains only unique values
--
-- Parameters:
--
--      i_array             - The array of any type to check
--      i_nulls_distinct    - if TRUE, NULL values are treated as distinct, otherwise they are considered duplicates
--
-- Returns:
--      TRUE                - if the array contains only unique values
--      FALSE               - if the array has at least one duplicate value
--
-------------------------------------------------------------------------------
RETURNS BOOLEAN AS $$
    SELECT cardinality($1) = (
        SELECT COUNT(DISTINCT x)
        FROM unnest($1) AS x
        WHERE i_nulls_distinct OR 
            x IS NOT NULL
    );
$$ LANGUAGE SQL IMMUTABLE SECURITY INVOKER;

ALTER FUNCTION pgarray.is_unique (ANYARRAY, BOOLEAN) OWNER TO pgutils_owner;

GRANT EXECUTE ON FUNCTION pgarray.is_unique (ANYARRAY, BOOLEAN) TO public;
