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

CREATE OR REPLACE FUNCTION pgutils.log_to_console(
    IN  i_log_message       TEXT,
    IN  i_add_timestamp     BOOLEAN DEFAULT TRUE
) RETURNS VOID AS
$$
-------------------------------------------------------------------------------
--
-- Function: pgutils.log_to_console(2)
-- Version:  0.1.0

--      Prints out a message to the console, optionally prefixed by current timestamp. Useful when a progress report is
--      handy during long operations.
--
-- Parameters:
--      i_log_message               - message to write into the console
--      i_add_timestamp             - if TRUE, message is prefixed by a timestamp, otherwise only the message is output
--
-------------------------------------------------------------------------------
DECLARE
BEGIN
    IF i_add_timestamp THEN
        RAISE NOTICE '%: %', clock_timestamp(), i_log_message;
    ELSE
        RAISE NOTICE '%', i_log_message;
    END IF;

    RETURN;
END;
$$
LANGUAGE plpgsql VOLATILE SECURITY INVOKER;

ALTER FUNCTION pgutils.log_to_console(TEXT, BOOLEAN) OWNER TO pgutils_owner;
GRANT EXECUTE ON FUNCTION pgutils.log_to_console(TEXT, BOOLEAN) TO public;