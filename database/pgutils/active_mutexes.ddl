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


