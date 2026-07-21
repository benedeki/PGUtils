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

CREATE OR REPLACE FUNCTION pgutils.can_role_modify_table_data(
    IN  i_schema_name           TEXT,
    IN  i_table_name            TEXT,
    IN  i_role_name             TEXT DEFAULT session_user,
    OUT can_modify              BOOLEAN
)  RETURNS BOOLEAN AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.can_role_modify_table_data(3)
-- Version:  0.1.0
--     Checks if the specified role has the privilege to modify the table's data in any form (INSERT, UPDATE, DELETE or
--     TRUNCATE),
--
-- Parameters:
--      i_schema_name           - Schema name of the table to check the permissions for
--      i_table_name            - Table name for which the permissions should be checked
--      i_role_name             - Name of the role for which the permissions should be checked. If not provided the
--                                user connected to the session is considered (not the owner of the function that
--                                calls this function even if `SECURITY DEFINER` is used).
--
-- Returns:
--      can_modify              - TRUE if the role has been granted at least one of INSERT, UPDATE, DELETE or
--                                TRUNCATE on the table, FALSE otherwise
--
-------------------------------------------------------------------------------
DECLARE
    _full_table_name    TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = i_role_name) THEN
        can_modify := FALSE;
        RETURN;
    END IF;

    _full_table_name := format('%I.%I', i_schema_name, i_table_name);

    can_modify :=
        has_table_privilege(i_role_name, _full_table_name, 'INSERT') OR
        has_table_privilege(i_role_name, _full_table_name, 'UPDATE') OR
        has_table_privilege(i_role_name, _full_table_name, 'DELETE') OR
        has_table_privilege(i_role_name, _full_table_name, 'TRUNCATE');

    RETURN;
END;
$$
LANGUAGE plpgsql VOLATILE SECURITY INVOKER;

ALTER FUNCTION pgutils.can_role_modify_table_data(TEXT, TEXT, TEXT) OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.can_role_modify_table_data(TEXT, TEXT, TEXT) TO public;
