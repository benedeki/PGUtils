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

DO
$do$
BEGIN
    IF EXISTS (
        SELECT FROM pg_catalog.pg_roles
        WHERE  rolname = 'pgutils_tester')
    THEN
        ALTER ROLE pgutils_tester
            LOGIN
            PASSWORD 'ChangeMe!'
            NOSUPERUSER
            INHERIT
            CREATEROLE
            NOCREATEDB
            NOREPLICATION;
       RAISE NOTICE 'Role "pgutils_tester" already exists. Skipping.';
    ELSE
        CREATE ROLE pgutils_tester
            LOGIN
            PASSWORD 'ChangeMe!'
            NOSUPERUSER
            INHERIT
            CREATEROLE
            NOCREATEDB
            NOREPLICATION;
    END IF;
    GRANT CREATE ON SCHEMA pgutils TO pgutils_tester;
END;
$do$;
