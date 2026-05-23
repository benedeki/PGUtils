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

CREATE OR REPLACE FUNCTION pgutils._suspend_constraints(
    IN  i_schema_name           TEXT,
    IN  i_table_name            TEXT,
    IN  i_constraint_names      TEXT[],
    IN  i_persistently          BOOLEAN,
    OUT constraint_name         TEXT,
    OUT constraint_type         CHAR
)  RETURNS SETOF record AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils._suspend_constraints(4)
-- Version:  0.1.0
--     The actual implementation of the `pgutils.suspend_constraints` function. The execution is separated for security
--     reasons, as the function needs to be defined as SECURITY DEFINER and logic to be executed by as a superuser.
--
-- Parameters:
--      i_schema_name           - Schema name of the table for which the constraints should be suspended
--      i_table_name            - Table name for which the constraints should be suspended
--      i_constraint_names      - Name of the constraints to suspend
--      i_persistently          - Flag that indicates whether the suspended constraints should be stored persistently so
--                                it last over transactions.
--
-- Returns:
--      constraint_name         - Name of the suspended constraint
--      constraint_type         - Type of the suspended constraint (e.g. 'c' for check constraint, 'f' for foreign key, etc.)
--
-------------------------------------------------------------------------------
DECLARE
    _user_can_alter_table   BOOLEAN;
    _target_table           TEXT;
    _table_oid              OID;
    _pk_field_ids           SMALLINT[];
    _command                TEXT;
    _r                      RECORD;
    _constraint_definition  TEXT;
BEGIN

    IF i_schema_name = 'pgutils' AND
       (i_table_name = 'suspended_constraints_in_transaction' OR i_table_name = 'suspended_constraints_persistently') THEN
        RAISE EXCEPTION 'Cannot suspend constraints on suspend constraints infrastructure tables.';
    END IF;

    _user_can_alter_table := pgutils.can_role_alter_table(i_schema_name, i_table_name);

    IF i_persistently AND NOT _user_can_alter_table THEN
        RAISE EXCEPTION 'The role % does not have permissions to alter the table %.%. Cannot persistently suspend the constraints.',
            session_user, i_schema_name, i_table_name;
    END IF;

    IF i_persistently THEN
        _target_table := 'pgutils.suspended_constraints_persistently';
    ELSE
        _target_table := 'pgutils.suspended_constraints_in_transaction';
    END IF;


    -- we might need to query the constraints twice, no need to always do the join with the analysis around
    SELECT PC.oid
    FROM pg_class PC
        INNER JOIN pg_namespace PNS ON PNS.oid = PC.relnamespace
    WHERE PNS.nspname = i_schema_name AND
        PC.relname = i_table_name
        INTO _table_oid;

    SELECT PCON.conkey
    FROM pg_constraint PCON
    WHERE PCON.conrelid = _table_oid AND
        PCON.contype = 'p'
    INTO _pk_field_ids;

    FOR _r IN
        SELECT
            i_schema_name,
            i_table_name,
            PCON.conname,
            pg_get_constraintdef(PCON.oid, TRUE),
            PCON.contype,
            PCON.convalidated,
            PCON.oid
        FROM pg_constraint PCON
        WHERE PCON.conrelid = _table_oid AND
            PCON.conname = ANY (i_constraint_names) AND
            -- don't want to include `NOT NULL` constraints that are part of the primary key, as they cannot be suspended separately
            (PCON.contype != 'n' OR NOT coalesce(PCON.conkey[1] = ANY(_pk_field_ids), false))
    LOOP
        IF NOT(_user_can_alter_table) AND NOT(_r.convalidated) THEN
        RAISE EXCEPTION
            'User % cannot suspend non-valid constraints on table %.%. It might affect data integrity without the permission to alter the table.',
            session_user, i_schema_name, i_table_name;
        END IF;

        _constraint_definition := pg_get_constraintdef(_r.oid, TRUE);
        _command := format(
            'INSERT INTO %s (' ||
            '   schema_name, table_name, constraint_name, definition, constraint_type, validated)' ||
            '   VALUES (%L, %L, %L, %L, %L, %L);' ||
            'ALTER TABLE %I.%I DROP CONSTRAINT %I;',
            _target_table,
            i_schema_name, i_table_name, _r.conname, _constraint_definition, _r.contype, _r.convalidated,
            i_schema_name, i_table_name, _r.conname);

        EXECUTE _command;
        constraint_name := _r.conname;
        constraint_type := _r.contype;
        RETURN NEXT;
    END LOOP;

    RETURN;
END;
$$
LANGUAGE plpgsql
VOLATILE SECURITY DEFINER
SET search_path = pg_temp, pg_catalog, public;

ALTER FUNCTION pgutils._suspend_constraints(TEXT, TEXT, TEXT[], BOOLEAN) OWNER TO postgres;
GRANT EXECUTE ON FUNCTION pgutils._suspend_constraints(TEXT, TEXT, TEXT[], BOOLEAN) TO pgutils_owner;
