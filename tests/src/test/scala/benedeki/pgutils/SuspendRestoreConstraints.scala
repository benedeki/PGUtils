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

import benedeki.testing.ExtraFunctions._
import benedeki.testing.classes.OriginalTestMethod
import org.postgresql.util.PSQLException
import org.scalactic.source
import org.scalatest.Tag
import org.scalatest.funsuite.AnyFunSuiteLike
import za.co.absa.db.balta.DBTestSuite
import za.co.absa.db.balta.classes.DBTable
import benedeki.testing.implicits.ArrayImplicits.StringArrayEnhancements
import benedeki.testing.implicits.DBTableImplicits.DBTableEnhancements
import benedeki.testing.implicits.DBFunctionImplicits.DBFunctionEnhancements

import scala.reflect.ClassTag

class SuspendRestoreConstraints extends DBTestSuite with OriginalTestMethod{

  test("Suspending and restoring constraints returns all existing constraints") {
    createTable()
    function("pgutils.suspend_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .execute(orderBy = "constraint_name") { qr =>
        assert(qr.hasNext, "The function did not return any result")
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

    function("pgutils.restore_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .execute(orderBy = "constraint_name") { qr =>
        assert(qr.hasNext, "The function did not return any result")
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
  }

  test("Suspended constraint allows entering invalid data, fails on restore") {
    val table = createTable()

    val row = function("pgutils.suspend_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .setParam("i_constraint_types", Array("c").toDbType)
      .callFunction()
    assert(row.getString("constraint_name").contains("chck_amount"))
    assert(row.getString("constraint_type").contains("c"))

    table.insert(
      ("id_simple", 1),
      ("foo", "test"),
      ("amount", -10)
    )

    val caught2 = intercept[PSQLException] {
      function("pgutils.restore_constraints")
        .setParam("i_schema_name", "pgutils_testing")
        .setParam("i_table_name", "simple_table")
        .perform()
    }

    assert(caught2.getMessage.contains("ERROR: check constraint \"chck_amount\" of relation \"simple_table\" is violated by some row"))
  }

  test("Suspended constraint allows entering invalid data, if fixed before restore it does not fail") {
    val table = createTable()

    val row = function("pgutils.suspend_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .setParam("i_constraint_types", Array("Unique").toDbType)
      .callFunction()
    assert(row.getString("constraint_name").contains("unq_foo"))
    assert(row.getString("constraint_type").contains("u"))

    table.insert(
      ("id_simple", 1),
      ("foo", "test"),
      ("amount", 11)
    )

    table.insert(
      ("id_simple", 2),
      ("foo", "test"),
      ("amount", 12)
    )

    dml("UPDATE pgutils_testing.simple_table SET foo = 'test2' WHERE id_simple = 2;")

    val row2 = function("pgutils.restore_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .callFunction()
    assert(row2.getString("constraint_name").contains("unq_foo"))
    assert(row2.getString("constraint_type").contains("u"))

  }

  test("Forcing non-valid on constraint resume lets invalid data in") {
    val table = createTable()

    val suspendedConstraints = function("pgutils.suspend_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .setParam("i_constraint_types", Array("Not Null", "c").toDbType)
      .execute(qr => qr.toList)
    assert(suspendedConstraints.size == 2, s"Expected 2 rows of suspended constraints, got ${suspendedConstraints.size}")

    table.insert(
      add("id_simple", 1)
      .addNull("foo")
      .add("amount", 100)
    )

    table.insert(
      ("id_simple", 2),
      ("foo", "x"),
      ("amount", -10)
    )

    function("pgutils.restore_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .setParam("i_enforced_valid_state", false)
      .perform()


    val result = table.all(){qr => qr.toList}
    assert(result.size == 2, s"Expected 2 rows, got ${result.size}")
  }

  test("Suspending constraint that is invalid where caller does not have permissions to alter the table throws an error") {
    val caught = intercept[PSQLException] {
      function("pgutils.suspend_constraints")
        .setParam("i_schema_name", "pgutils_testing")
        .setParam("i_table_name", "table1")
        .setParam("i_constraint_types", Array("c").toDbType)
        .perform()
    }
    assert(caught.getMessage.startsWith("ERROR: User pgutils_tester cannot suspend non-valid constraints on table pgutils_testing.table1."))
  }

  test("Trying to suspend constraints persistently on table where caller does not have permissions to alter the table throws an error") {
    val caught = intercept[PSQLException] {
      function("pgutils.suspend_constraints")
        .setParam("i_schema_name", "pgutils_testing")
        .setParam("i_table_name", "table2")
        .setParamNull("i_constraint_types")
        .setParam("i_persistently", true)
        .perform()
    }
    println(caught.getMessage)
    assert(caught.getMessage.startsWith("ERROR: The user pgutils_tester does not have permissions to alter the table pgutils_testing.table2. Cannot persistently suspend the constraints."))
  }

  test("Cannot suspend constrains on pgutils.suspended_constraints_in_transaction") {
    val caught = intercept[PSQLException] {
      function("pgutils.suspend_constraints")
        .setParam("i_schema_name", "pgutils")
        .setParam("i_table_name", "suspended_constraints_in_transaction")
        .perform()
    }
    assert(caught.getMessage.startsWith("ERROR: Cannot suspend constraints on suspend constraints infrastructure tables."))
  }

  test("Cannot suspend constrains on pgutils.suspended_constraints_persistently") {
    val caught = intercept[PSQLException] {
      function("pgutils.suspend_constraints")
        .setParam("i_schema_name", "pgutils")
        .setParam("i_table_name", "suspended_constraints_persistently")
        .perform()
    }
    assert(caught.getMessage.startsWith("ERROR: Cannot suspend constraints on suspend constraints infrastructure tables."))
  }

  test("Suspending constraints where caller has no ALTER and no DML privilege at all throws an error") {
    val caught = intercept[PSQLException] {
      function("pgutils.suspend_constraints")
        .setParam("i_schema_name", "pgutils")
        .setParam("i_table_name", "active_mutexes")
        .perform()
    }
    assert(caught.getMessage.startsWith(
      "ERROR: User pgutils_tester has no legitimate reason to suspend constraints on table pgutils.active_mutexes"))
  }

  test("Suspending constraints non-persistently succeeds for a caller with only DML privileges (no ALTER)") {
    // pgutils_tester owns neither table1 nor table2, but test_tables.ddl grants it
    // SELECT/INSERT/UPDATE/DELETE on table2 - that alone should now be enough to pass the new gate,
    // as long as no NOT VALID constraint is involved (see the existing "non-valid constraint" test for that case).
    function("pgutils.suspend_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table2")
      .execute(orderBy = "constraint_name") { qr =>
        assert(qr.hasNext, "Expected the caller's DML privileges to be sufficient for non-persistent suspension")
      }

    function("pgutils.restore_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table2")
      .perform()
  }

  testForFail[PSQLException]("Constraints are suspended but not restored throws an exception", isErrorOfLeftoverConstraint) {
    createTable()
    function("pgutils.suspend_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .perform()
  }

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

  protected def testForFail[E <: AnyRef](testName: String, failVerification:E => Option[String], testTags: Tag*)
                                        (testFun: => Any /* Assertion */)
                                        (implicit classTag: ClassTag[E], pos: source.Position): Unit = {
    val dbTestFun: () => Unit = () => {
      val caught = intercept[E] {
        testFun
        dbConnection.connection.commit()
      }
      val fail = failVerification(caught)
      val assertError = fail.getOrElse("")
      assert(fail.isEmpty, assertError)
    }
    super[OriginalTestMethod].test(testName, testTags: _*)(dbTestFun())
  }

  private def isErrorOfLeftoverConstraint(exception: PSQLException): Option[String] = {
    val pattern = """^ERROR: Constraint "[^"+].+ has not been resumed[\s\S]+""".r
    exception.getMessage match {
      case pattern() => None
      case _ => Some("Expected exception: Constraint has not been restored, instead got a message: " + exception.getMessage)
    }
  }
}
