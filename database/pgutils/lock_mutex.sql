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

CREATE OR REPLACE FUNCTION pgutils.lock_mutex(
    IN i_mutex_name TEXT
) RETURNS VOID AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.lock_mutex(1)
-- Version:  0.1.0
--
--      The goal of this function is to implement concurrent operation execution - operation is given in the input
--      parameter.
--
--      Note: call this function at the beginning of an operation (usually a wider UPDATE/INSERT) that you want to
--          prevent concurrent execution of, and the release will happen automatically when the transaction finishes or
--          rolls back. This is because the table pgutils.active_mutexes is locked for the given operation.
--
-- Parameters:
--      i_mutex_name - Name of the operation that will perform the lock.
--
-------------------------------------------------------------------------------
DECLARE
BEGIN

    PERFORM 1
    FROM pgutils.active_mutexes
    WHERE mutex_name = i_mutex_name
        FOR UPDATE;

    IF NOT found THEN
            INSERT INTO pgutils.active_mutexes (mutex_name)
            VALUES (i_mutex_name)
            ON CONFLICT DO nothing;
    
            -- this is to ensure the lock is re-applied after the conflict has been resolved
            PERFORM lock_mutex(i_mutex_name);
    END IF;

    RETURN;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

ALTER FUNCTION pgutils.lock_operational_mutex(TEXT) OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.lock_operational_mutex(TEXT) TO public;


CREATE UNLOGGED TABLE pgutils.active_mutexes
(
    mutex_name TEXT NOT NULL,
    CONSTRAINT active_mutexes_pk PRIMARY KEY (mutex_name)
);

COMMENT ON TABLE pgutils.active_mutexes IS
    'Used when you want to allow only one actor to modify some table and once its operation is done, it should release the lock. '
        'A row added into this table represents a registration of such operation.';

COMMENT ON COLUMN pgutils.active_mutexes.mutex_name IS
    'Unique representation of a given operation, usually a DB function name that wants to avoid races';

ALTER TABLE pgutils.active_mutexes OWNER to pgutils_owner;


