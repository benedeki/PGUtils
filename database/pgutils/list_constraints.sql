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

CREATE OR REPLACE FUNCTION pgutils.list_constraints(
    IN  i_schema_name           TEXT,
    IN  i_table_name            TEXT,
    OUT constraint_name         TEXT,
    OUT constraint_type         CHAR
)  RETURNS SETOF record AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.list_constraints(2)
-- Version:  0.1.0
--     Returns all the constraints of a given table.
--
-- Parameters:
--      i_schema_name           - Schema name of the table for which the constraints should be listed.
--      i_table_name            - Table name for which the constraints should be listed.
--
-- Returns:
--      constraint_name         - Name of the constraint
--      constraint_type         - Type of the constraint (e.g. 'c' for check constraint, 'f' for foreign key, etc.)
--
-------------------------------------------------------------------------------
    SELECT
        PCON.conname,
        PCON.contype
    FROM pg_class PC
        INNER JOIN pg_namespace PNS  ON PNS.oid = PC.relnamespace
        INNER JOIN pg_constraint PCON ON PCON.conrelid = PC.oid
    WHERE PNS.nspname = i_schema_name AND
        PC.relname  = i_table_name;
$$
LANGUAGE sql VOLATILE SECURITY DEFINER;

ALTER FUNCTION pgutils.list_constraints(TEXT, TEXT) OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.list_constraints(TEXT, TEXT) TO public;


CREATE OR REPLACE FUNCTION pgutils.list_constraints(
    IN  i_table_name            TEXT,
    OUT constraint_name         TEXT,
    OUT constraint_type         CHAR
)  RETURNS SETOF record AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.list_constraints(1)
-- Version:  0.1.0
--     Returns all the constraints of a given table.
--     This is an overloaded version of `pgutils.list_constraints` which injects 'public' as the
--     default schema.
--
-- Parameters:
--      i_table_name            - Table name for which the constraints are to be listed.
--
-- Returns:
--      constraint_name         - Name of the constraint
--      constraint_type         - Type of the constraint (e.g. 'c' for check constraint, 'f' for foreign key, etc.)
--
-------------------------------------------------------------------------------
    SELECT DC.constraint_name, DC.constraint_type
    FROM pgutils.list_constraints('public', i_table_name) DC
$$
LANGUAGE sql STABLE SECURITY DEFINER;

ALTER FUNCTION pgutils.list_constraints(TEXT) OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.list_constraints(TEXT) TO public;
