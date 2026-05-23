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

CREATE TABLE IF NOT EXISTS pgutils.suspended_constraints_persistently(
    schema_name             TEXT NOT NULL,
    table_name              TEXT NOT NULL,
    constraint_name         TEXT NOT NULL,
    definition              TEXT NOT NULL,
    constraint_type         CHAR NOT NULL,
    validated               BOOLEAN NOT NULL,
    suspended_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT pk_suspended_constraints_persistently
        PRIMARY KEY (schema_name, table_name, constraint_name)
);

COMMENT ON TABLE pgutils.suspended_constraints_persistently IS  $COMMENT$
A table to hold the constraints where suspension persists past the transaction.
 It belongs to superuser `postgres`, because it would offer a chance for SQL injection otherwise. As only superuser can
 reads and most of all writes to this table, it's safe to consider it a sufficient protection. Because if a superuser
 access would be compromised to tinker with thins table, then the whole database is already compromised.
 $COMMENT$;

ALTER TABLE pgutils.suspended_constraints_persistently OWNER TO postgres;
-- to be able to restore all constraints pgutils_owner needs to be able to read the table
GRANT SELECT ON TABLE pgutils.suspended_constraints_persistently TO pgutils_owner;
