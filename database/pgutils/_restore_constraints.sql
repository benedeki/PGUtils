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

CREATE OR REPLACE FUNCTION pgutils._restore_constraints(
    IN  i_schema_name           TEXT,
    IN  i_table_name            TEXT,
    IN  i_enforced_valid_state  BOOLEAN,
    OUT constraint_name         TEXT,
    OUT constraint_type         CHAR,
    OUT validated               BOOLEAN
)  RETURNS SETOF RECORD AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils._restore_constraints(3)
-- Version:  0.1.0
--     The actual implementation of the `pgutils.restore_constraints` function. The execution is separated for security
--     reasons, as the function needs to be defined as SECURITY DEFINER and logic to be executed by as a superuser.
--
-- Parameters:
--      i_schema_name           - Schema name of the table for which the constraints should be restored
--      i_table_name            - Table name for which the constraints should be restored
--      i_enforced_valid_state  - Flag that can enforce the constraints to be restored as NOT VALID regardless of their
--                                previous state. This can be useful in case when the constraints were suspended for a
--                                large data change where the data are fairly certain to be OK and/or just want to
--                                validate the constraints later in a separate transaction to avoid locking the table
--                                for too long. By default, the constraints will be restored to their previous state,
--                                meaning that if a constraint was valid before disabling, it will be restored as valid,
--                                and if it was not valid, it will be restored as not valid.
--                                NB!
--                                `NOT VALID` constraint means, it's not guaranteed that the existing data in the table
--                                satisfy the constraint, but any new data inserted or updated after the constraint is
--                                restored will be validated against the constraint.
--                                To validate the existing data against the constraint, you can use
--                                `ALTER TABLE schema_name.table_name VALIDATE CONSTRAINT constraint_name;`
--                                command,  which will validate the existing data and, if successful, will mark the
--                                constraint as valid.
--                                NB!
--                                Only not null and check constraints and foreign keys can be restored as NOT VALID, as
--                                the other types of constraints (e.g. primary key, unique constraint, etc.) are always
--                                valid when created.
--
-- Returns:
--      constraint_name         - Name of the restored constraint
--
-------------------------------------------------------------------------------
DECLARE
    _non_privileged_user    BOOLEAN;
    _r                      RECORD;
    _constraints_command    TEXT := '';
BEGIN
    _non_privileged_user := NOT pgutils.can_role_alter_table(i_schema_name, i_table_name);

    FOR _r IN
        WITH scit AS (
            DELETE
            FROM pgutils.suspended_constraints_in_transaction
            WHERE schema_name = i_schema_name AND
                table_name = i_table_name
            RETURNING *
        ),
        scp AS (
            DELETE
            FROM pgutils.suspended_constraints_persistently
            WHERE schema_name = i_schema_name AND
                table_name = i_table_name
                RETURNING *
        )
        SELECT scit.schema_name, scit.table_name, scit.constraint_name, scit.definition, scit.constraint_type, scit.validated
        FROM scit
        UNION
        SELECT scp.schema_name, scp.table_name, scp.constraint_name, scp.definition, scp.constraint_type, scp.validated
        FROM scp
    LOOP
        IF _non_privileged_user THEN
            IF NOT(_r.validated) THEN
                RAISE EXCEPTION
                    'User % cannot restore non-valid constraint % on table %.%. It might affect data integrity without the permission to alter the table.',
                    session_user, _r.constraint_name, i_schema_name, i_table_name;
            END IF;

            -- enforcing a state change to another that it was before requires a privileged user
            -- but the other combination doesn't need to be checked because of the condition above
            IF (NOT(i_enforced_valid_state) AND _r.validated) THEN
                RAISE EXCEPTION
                    'User % cannot restore constraint % on table %.%. The constraint validity state would change and the user does not have permission to alter the table.',
                    session_user, _r.constraint_name, i_schema_name, i_table_name;
            END IF;
        END IF;
        _constraints_command := _constraints_command || format(
            'ADD CONSTRAINT %I %s%s,',
            _r.constraint_name,
            _r.definition,
            CASE
                WHEN i_enforced_valid_state THEN ''
                WHEN NOT(i_enforced_valid_state) AND _r.constraint_type in ('c', 'f', 'n') THEN ' NOT VALID'
                ELSE CASE WHEN _r.validated THEN '' ELSE ' NOT VALID' END
            END
        );
        constraint_name := _r.constraint_name;
        constraint_type := _r.constraint_type;
        validated := _r.validated;
        RETURN NEXT;
    END LOOP;

    IF _constraints_command <> '' THEN
        _constraints_command := left(_constraints_command, length(_constraints_command) - 1); -- remove the last comma
        _constraints_command := format('ALTER TABLE %I.%I %s;', i_schema_name, i_table_name, _constraints_command);
        EXECUTE _constraints_command;
    END IF;

    RETURN;
END;
$$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER
SET search_path = pg_temp, pg_catalog, public;

ALTER FUNCTION pgutils._restore_constraints(TEXT, TEXT, BOOLEAN) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION pgutils._restore_constraints(TEXT, TEXT, BOOLEAN) TO pgutils_owner;
