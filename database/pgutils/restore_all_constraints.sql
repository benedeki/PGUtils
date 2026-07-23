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

CREATE OR REPLACE FUNCTION pgutils.restore_all_constraints(
    IN  i_enforced_valid_state  BOOLEAN DEFAULT NULL,
    OUT schema_name             TEXT,
    OUT table_name              TEXT,
    OUT constraint_name         TEXT,
    OUT constraint_type         CHAR,
    OUT validated               BOOLEAN
)  RETURNS SETOF RECORD AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.restore_all_constraints(1)
-- Version:  0.1.0
--     Restores all the constraints that were temporarily suspended, presumably by `pgutils.suspend_constraints`
--     function, and returns the schema, table name and info of the restored constraint.
--
-- Parameters:
--      i_enforced_valid_state  - (optional) Setting that can enforce the constraints to be restored in certain validity
--                                state regardless  of previous state. If set to TRUE, all the constraints will be
--                                restored as VALID, if set to FALSE, all the constraints will be restored as NOT VALID,
--                                and if set to NULL (default), the constraints will be restored to their previous state,
--                                NB!
--                                `NOT VALID` constraint means, it's not guaranteed that the existing data in the table
--                                satisfy the constraint, but any new data inserted or updated after the constraint is
--                                restored will be validated against the constraint.
--                                To validate the existing data against the constraint, you can use
--                                `ALTER TABLE schema_name.table_name VALIDATE CONSTRAINT constraint_name;`
--                                command,  which will validate the existing data and, if successful, will mark the
--                                constraint as valid.
--
-- Returns:
--      schema_name             - Schema name of the table for which the constraint has been restored
--      table_name              - Table name for which the constraint has been restored
--      constraint_name         - Name of the restored constraint
--      constraint_type         - Type of the suspended constraint (e.g. 'c' for check constraint, 'f' for foreign key, etc.)
--      validated               - Whether the constraint is valid after being restored
--
-------------------------------------------------------------------------------
DECLARE
    _r record;
BEGIN
    FOR _r IN
        SELECT DISTINCT SCIT.schema_name, SCIT.table_name
        FROM pgutils.suspended_constraints_in_transaction SCIT
        UNION
        SELECT DISTINCT SCP.schema_name, SCP.table_name
        FROM pgutils.suspended_constraints_persistently SCP
        -- TODO Restore constraints needs to be ordered https://github.com/benedeki/PGUtils/issues/16
    LOOP
        RETURN QUERY
        SELECT _r.schema_name, _r.table_name, RC.constraint_name, RC.constraint_type, RC.validated
        FROM pgutils._restore_constraints(_r.schema_name, _r.table_name, i_enforced_valid_state) RC;
    END LOOP;

    RETURN;
END;
$$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

ALTER FUNCTION pgutils.restore_all_constraints(BOOLEAN) OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.restore_all_constraints(BOOLEAN) TO public;
