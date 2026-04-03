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
DECLARE
    _server_count   CONSTANT INT := 9223; -- Number of unique prefixes to fit into 64-bit integer
    _sequence_range CONSTANT BIGINT := 1000000000000000; -- the range for sequence values to fit into 64-bit integer (1 quadrillion)
    _server_id      BIGINT;
    _sequence_start BIGINT;
    _sequence_end   BIGINT;
    _command        TEXT;
    _schema_name    CONSTANT TEXT := 'pgutils';
    _sequence_name  CONSTANT TEXT := 'global_id_seq';
BEGIN
    PERFORM 1
    FROM information_schema.sequences
    WHERE sequence_name = _schema_name AND
        sequence_schema = _sequence_name;

    IF NOT found     THEN
       -- _server_id can be calculated in various ways, the key is to have a deterministic prescription that returns a
       -- number between 1 and _server_count and is expected to differ between servers.
        _server_id := abs(hashtextextended(inet_server_addr()::text, 0)) % 9222;

        _sequence_start := (_server_id + 1) * _sequence_range + 1; -- (_server_id + 1) to avoid starting at 0 for server_id 0, thus 32 bits to not interfering
        _sequence_end := (_server_id + 2) * _sequence_range;

        _command := format(
                'CREATE SEQUENCE IF NOT EXISTS %s.%s INCREMENT 1 START %s MINVALUE %s MAXVALUE %s CACHE 1;',
                _schema_name,
                _sequence_name,
                _sequence_start,
                _sequence_start,
                _sequence_end
            );

        EXECUTE _command;

        RAISE NOTICE 'Sequence submitted with command: `%`', _command;

        ALTER SEQUENCE utils.global_id_seq OWNER TO util_functions_owner;
    ELSE
        RAISE NOTICE 'Sequence % already exists. Skipping creation.', _sequence_name;
        RETURN;
    END IF;
END;
$do$;

CREATE OR REPLACE FUNCTION pgutils.global_id() RETURNS BIGINT AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.global_id(0)
-- Version:  0.1.0
--
--      Generates a unique ID, with the proper setup unique over all your servers
--
-- Returns:
--      - The next ID to use
--
-------------------------------------------------------------------------------
DECLARE
BEGIN
    RETURN nextval('pgutils.global_id_seq');
END;
$$
LANGUAGE plpgsql VOLATILE SECURITY DEFINER;

ALTER FUNCTION pgutils.global_id() OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.global_id() TO PUBLIC;
