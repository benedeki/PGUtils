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

CREATE OR REPLACE FUNCTION pgutils.suspend_constraints(
    IN  i_schema_name           TEXT,
    IN  i_table_name            TEXT,
    IN  i_constraint_types      TEXT[] DEFAULT NULL,
    IN  i_persistently          BOOLEAN DEFAULT FALSE,
    OUT constraint_name         TEXT,
    OUT constraint_type         CHAR
)  RETURNS SETOF record AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.suspend_constraints(4)
-- Version:  0.1.0
--     suspends all the constraints of the specified types for a given table and stores their definitions in a temporary
--     table. This allows to later restore the constraints using `pgutils.restore_constraints` or
--     `pgutils.restore_all_constraints` function.
--
-- Parameters:
--      i_schema_name           - Schema name of the table for which the constraints should be suspended.
--      i_table_name            - Table name for which the constraints should be suspended.
--      i_constraint_types      - (optional) Array of constraint types to suspend. If not provided, all types of
--                                constraints will be suspended.
--      i_persistently          - (optional) Flag that indicates whether the suspended constraints should be stored
--                                persistently so it last over transactions.
--                                NB!
--                                Use persistence CAREFULLY RESPONSIBLY, as the constraints will be suspended until they
--                                are explicitly restored and can lead to data integrity issues.
--                                Only a user with grant to alter the table can use this option, otherwise the function
--                                will raise an error.
--
-- Returns:
--      constraint_name         - Name of the suspended constraint
--      constraint_type         - Type of the suspended constraint (e.g. 'c' for check constraint, 'f' for foreign key, etc.)
--
-------------------------------------------------------------------------------
DECLARE
    _constraint_types CHAR[];
    _ALL_CONSTRAINTS CONSTANT CHAR[] = ARRAY['c', 'f', 'p', 'u', 'n', 'x', 't'];
    _constraint_names TEXT[];
BEGIN
    IF i_constraint_types IS NULL THEN
        _constraint_types := _ALL_CONSTRAINTS;
    ELSE
        SELECT array_agg(
                   CASE upper(CT.ct)
                       WHEN 'CHECK' THEN 'c'
                       WHEN 'FOREIGN KEY' THEN 'f'
                       WHEN 'PRIMARY KEY' THEN 'p'
                       WHEN 'UNIQUE' THEN 'u'
                       WHEN 'NOT NULL' THEN 'n'
                       WHEN 'EXCLUDE' THEN 'x'
                       WHEN 'CONSTRAINT TRIGGER' THEN 't'
                       ELSE lower(left(CT.ct, 1))
                   END
               )::CHAR[]
        FROM unnest(i_constraint_types) CT
        INTO _constraint_types;
    END IF;

    SELECT array_agg(LS.constraint_name)
    FROM pgutils.list_constraints(i_schema_name, i_table_name) LS
    WHERE LS.constraint_type = ANY(_constraint_types)
    INTO _constraint_names;

    RETURN QUERY
    SELECT SCP.constraint_name, SCP.constraint_type
    FROM pgutils._suspend_constraints(i_schema_name, i_table_name, _constraint_names, i_persistently) SCP;

    RETURN;
END;
$$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

ALTER FUNCTION pgutils.suspend_constraints(TEXT, TEXT, TEXT[], BOOLEAN) OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.suspend_constraints(TEXT, TEXT, TEXT[], BOOLEAN) TO public;


CREATE OR REPLACE FUNCTION pgutils.suspend_constraints(
    IN  i_table_name            TEXT,
    IN  i_constraint_types      TEXT[] DEFAULT NULL,
    IN  i_persistently          BOOLEAN DEFAULT FALSE,
    OUT constraint_name         TEXT,
    OUT constraint_type         CHAR
)  RETURNS SETOF record AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.suspend_constraints(3)
-- Version:  0.1.0
--     suspends all the constraints of the specified types for a given table and stores their definitions in a temporary
--     table. This allows to later restore the constraints using `pgutils.restore_constraints` or
--     `pgutils.restore_all_constraints` function.
--     This is an overloaded version of the `pgutils.suspend_constraints` function, which injects 'public' as the
--     default schema,
--
-- Parameters:
--      i_table_name            - Table name for which the constraints should be suspended
--      i_constraint_types      - (optional) Array of constraint types to suspend. If not provided, all types of
--                                constraints will be suspended.
--      i_persistently          - (optional) Flag that indicates whether the suspended constraints should be stored
--                                persistently so it last over transactions.
--                                NB!
--                                Use persistence CAREFULLY RESPONSIBLY, as the constraints will be suspended until they
--                                are explicitly restored and can lead to data integrity issues.
--                                Only a user with grant to alter the table can use this option, otherwise the function
--                                will raise an error.
--                                constraints will be suspended.
--
-- Returns:
--      constraint_name         - Name of the suspended constraint
--      constraint_type         - Type of the suspended constraint (e.g. 'c' for check constraint, 'f' for foreign key, etc.)
--
-------------------------------------------------------------------------------
    SELECT DC.constraint_name, DC.constraint_type
    FROM pgutils.suspend_constraints('public', i_table_name, i_constraint_types, i_persistently) DC
$$
LANGUAGE sql VOLATILE SECURITY DEFINER;

ALTER FUNCTION pgutils.suspend_constraints(TEXT, TEXT[], BOOLEAN) OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.suspend_constraints(TEXT, TEXT[], BOOLEAN) TO public;
