CREATE TABLE IF NOT EXISTS pgutils_testing.table1
(
    id_table1 bigint NOT NULL,
    table1_name text,
    amount INTEGER,
    PRIMARY KEY (id_table1)
);

CREATE TABLE IF NOT EXISTS pgutils_testing.table2
(
    id_table2 bigint NOT NULL,
    key_table1 bigint REFERENCES pgutils_testing.table1 (id_table1) ON DELETE CASCADE,
    table2_name text NOT NULL,
    PRIMARY KEY (id_table2)
);

ALTER TABLE pgutils_testing.table1 OWNER to pgutils_owner;
ALTER TABLE pgutils_testing.table2 OWNER to pgutils_owner;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint C
        JOIN pg_class T ON T.oid = C.conrelid
        JOIN pg_namespace NS ON NS.oid = T.relnamespace
        WHERE C.conname = 'table1_check' AND
            T.relname = 'table1' AND
            NS.nspname = 'pgutils_testing'
    ) THEN
        ALTER TABLE pgutils_testing.table1
            ADD CONSTRAINT table1_check CHECK (amount > 0) NOT VALID;
    END IF;
END$$;

GRANT SELECT, INSERT, UPDATE, DELETE ON pgutils_testing.table1 TO pgutils_tester;
GRANT SELECT, INSERT, UPDATE, DELETE ON pgutils_testing.table2 TO pgutils_tester;
