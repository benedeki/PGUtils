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

CREATE OR REPLACE FUNCTION pgutils._trg_suspended_constraints_in_transaction_empty_check()
    RETURNS trigger AS
    -------------------------------------------------------------------------------
--
-- Function: pgutils._trg_suspended_constraints_in_transaction_empty_check(0)
-- Version:  0.1.0
--
--      A trigger function to ensure that the constraints table has been cleaned before the end of transaction, meaning
--      all the constraints have been re-enabled. This is to prevent the situation when a transaction suspends a
--      constraint, but fails to re-enable it, which can lead to data integrity issues.
--
-- Returns:
--      - The new row value, but should actually never reach this point, because the trigger should raise an exception
--        if the constraint_name column is not null, which means that the record has not been removed from the table
-------------------------------------------------------------------------------

$$
BEGIN
    IF NEW.constraint_name IS NOT NULL THEN
        RAISE EXCEPTION 'Constraint "%" has not been resumed', NEW.constraint_name;
    END IF;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;
