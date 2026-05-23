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

CREATE OR REPLACE FUNCTION pgutils.can_role_alter_table(
    IN  i_schema_name           TEXT,
    IN  i_table_name            TEXT,
    IN  i_role_name             TEXT DEFAULT session_user,
    OUT can_alter               BOOLEAN
)  RETURNS BOOLEAN AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.can_role_alter_table(3)
-- Version:  0.1.0
--     Checks if the specified role has permissions to alter the given table. The function checks if the role is a
--     superuser or a member of the rds_superuser role (in case of AWS Aurora), then it checks if the role is the actual
--     owner of the table or a member of the owning role. If any of these conditions is true, the function returns TRUE,
--     otherwise FALSE.
--
-- Parameters:
--      i_schema_name           - Schema name of the table to check the permissions for
--      i_table_name            - Table name for which the permissions should be checked
--      i_role_name             - Name of the role for which the permissions should be checked. If not provided the user
--                                connected to the session is considered (not the owner of the function that calls this
--                                function even if `SECURITY DEFINER` is used).
--
-- Returns:
--      can_alter               - TRUE if the role has permissions to alter the table, FALSE otherwise
--
-------------------------------------------------------------------------------
DECLARE
    _AWS_AURORA_SUPERUSER_ROLE_NAME         CONSTANT TEXT := 'rds_superuser';
    _table_owner_oid                        OID;
    _table_owner                            TEXT;
BEGIN

    -- superusers can alter any table, so we can skip the rest of the checks if the role is a superuser
    SELECT rolsuper
    FROM pg_roles
    WHERE rolname = i_role_name
    INTO can_alter;

    IF can_alter THEN
        RETURN;
    END IF;

    -- AWS Aurora doesn't have superusers per se, but it has a role with similar permissions called rds_superuser
    SELECT true
    FROM pg_roles R
        JOIN pg_auth_members AM ON R.oid = AM.roleid
        JOIN pg_roles U ON U.oid = AM.member
    WHERE R.rolname = _AWS_AURORA_SUPERUSER_ROLE_NAME AND
        U.rolname = i_role_name
    INTO can_alter;

    IF found THEN
            RETURN;
    END IF;

    -- most commonly the user is the direct owner of the table
    SELECT C.relowner, pg_get_userbyid(C.relowner)
    FROM pg_class C
        JOIN pg_namespace N ON C.relnamespace = N.oid
    WHERE N.nspname = i_schema_name AND
        C.relname = i_table_name
    INTO _table_owner_oid, _table_owner;

    IF (_table_owner = i_role_name) THEN
        can_alter := TRUE;
    ELSE
        -- check if the user is a member of the role that owns the table, which also allows to alter the table
        WITH RECURSIVE member_closure AS (
            SELECT _table_owner_oid AS member_oid
            UNION
            SELECT m.member
            FROM pg_auth_members m
                JOIN member_closure mc ON m.roleid = mc.member_oid
        )
        SELECT EXISTS(
            SELECT 1
            FROM member_closure mc
                     JOIN pg_roles r ON r.oid = mc.member_oid
            WHERE r.rolname = i_role_name
        )
        INTO can_alter;
    END IF;

    RETURN;
END;
$$
LANGUAGE plpgsql VOLATILE SECURITY INVOKER;


ALTER FUNCTION pgutils.can_role_alter_table(TEXT, TEXT, TEXT) OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.can_role_alter_table(TEXT, TEXT, TEXT) TO public;
