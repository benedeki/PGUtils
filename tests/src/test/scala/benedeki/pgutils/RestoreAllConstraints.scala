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

package benedeki.pgutils

import benedeki.testing.ExtraFunctions.ddl
import za.co.absa.db.balta.DBTestSuite
import za.co.absa.db.balta.classes.{DBTable, QueryResultRow}

class RestoreAllConstraints extends DBTestSuite{
  private def createTable():DBTable = {
    ddl(
      """
        |CREATE TABLE IF NOT EXISTS pgutils_testing.simple_table
        |(
        |    id_simple bigint NOT NULL,
        |    foo text,
        |    amount integer NOT NULL,
        |    PRIMARY KEY (id_simple),
        |    CONSTRAINT unq_foo UNIQUE (foo),
        |    CONSTRAINT chck_amount CHECK (amount >= 0)
        |);
        |""".stripMargin)

    table("pgutils_testing.simple_table")
  }

  private def assertRestoreRow(row: QueryResultRow, tableName: String, constraintName: String, constraintType: String): Unit = {
    assert(row.getString("schema_name").contains("pgutils_testing"))
    assert(row.getString("table_name").contains(tableName))
    assert(row.getString("constraint_name").contains(constraintName))
    assert(row.getString("constraint_type").contains(constraintType))
  }

  test("Restore all constraints") {
    createTable()

    function("pgutils.suspend_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .setParamNull("i_constraint_types")
      .setParam("i_persistently", true)
      .execute(orderBy = "constraint_name") { qr =>
        val row1 = qr.next()
        assert(row1.getString("constraint_name").contains("chck_amount"))
        assert(row1.getString("constraint_type").contains("c"))
        val row2 = qr.next()
        assert(row2.getString("constraint_name").contains("simple_table_amount_not_null"))
        assert(row2.getString("constraint_type").contains("n"))
        val row3 = qr.next()
        assert(row3.getString("constraint_name").contains("simple_table_pkey"))
        assert(row3.getString("constraint_type").contains("p"))
        val row4 = qr.next()
        assert(row4.getString("constraint_name").contains("unq_foo"))
        assert(row4.getString("constraint_type").contains("u"))
        assert(!qr.hasNext, "The function returned more than 4 results")
      }

    function("pgutils.suspend_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table2")
      .execute(orderBy = "constraint_name") { qr =>
        val row1 = qr.next()
        assert(row1.getString("constraint_name").contains("table2_key_table1_fkey"))
        assert(row1.getString("constraint_type").contains("f"))
        val row2 = qr.next()
        assert(row2.getString("constraint_name").contains("table2_pkey"))
        assert(row2.getString("constraint_type").contains("p"))
        val row3 = qr.next()
        assert(row3.getString("constraint_name").contains("table2_table2_name_not_null"))
        assert(row3.getString("constraint_type").contains("n"))
        assert(!qr.hasNext, "The function returned more than 3 results")
      }

    function("pgutils.restore_all_constraints")
      .execute(orderBy = "table_name, constraint_name") { qr =>
        assert(qr.hasNext, "The function did not return any result")
        assertRestoreRow(qr.next(), "simple_table", "chck_amount", "c")
        assertRestoreRow(qr.next(), "simple_table", "simple_table_amount_not_null", "n")
        assertRestoreRow(qr.next(), "simple_table", "simple_table_pkey", "p")
        assertRestoreRow(qr.next(), "simple_table", "unq_foo", "u")
        assertRestoreRow(qr.next(), "table2", "table2_key_table1_fkey", "f")
        assertRestoreRow(qr.next(), "table2", "table2_pkey", "p")
        assertRestoreRow(qr.next(), "table2", "table2_table2_name_not_null", "n")
        assert(!qr.hasNext, "The function returned more than 7 results")
      }
  }

}
