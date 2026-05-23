package benedeki.pgutils

import benedeki.testing.ExtraFunctions.ddl
import benedeki.testing.implicits.ArrayImplicits.StringArrayEnhancements
import za.co.absa.db.balta.DBTestSuite
import za.co.absa.db.balta.classes.DBTable

class SuspendConstraintsByName extends DBTestSuite{
  /*
  The test here is just verifies the returned values from the function. The actual suspension effectivity of the
  constraints suspension is tested `SuspendRestoreConstraints` test suite.
  */

  private def createTable():DBTable = {
    ddl(
      """
        |CREATE TABLE IF NOT EXISTS pgutils_testing.simple_table
        |(
        |    id_simple bigint NOT NULL,
        |    foo text,
        |    foo2 text,
        |    amount integer NOT NULL,
        |    CONSTRAINT unq_foo UNIQUE (foo),
        |    CONSTRAINT unq_foo2 UNIQUE (foo2),
        |    CONSTRAINT chck_amount CHECK (amount >= 0)
        |);
        |""".stripMargin)

    table("pgutils_testing.simple_table")
  }
  test("Suspend selected constraints only") {
    createTable()
    function("pgutils.suspend_constraints_by_name")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .setParam("i_constraint_names", Array("unq_foo", "chck_amount").toDbType)
      .execute(orderBy = "constraint_name") { qr =>
        assert(qr.hasNext, "The function did not return any result")
        val row1 = qr.next()
        assert(row1.getString("constraint_name").contains("chck_amount"))
        assert(row1.getString("constraint_type").contains("c"))
        val row2 = qr.next()
        assert(row2.getString("constraint_name").contains("unq_foo"))
        assert(row2.getString("constraint_type").contains("u"))
        assert(!qr.hasNext, "The function returned more than 2 results")
      }
  }

  test("Ignores non-existent constraints") {
    createTable()
    function("pgutils.suspend_constraints_by_name")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "simple_table")
      .setParam("i_constraint_names", Array("unq_foo2", "chck_amount", "xxxx").toDbType)
      .execute(orderBy = "constraint_name") { qr =>
        assert(qr.hasNext, "The function did not return any result")
        val row1 = qr.next()
        assert(row1.getString("constraint_name").contains("chck_amount"))
        assert(row1.getString("constraint_type").contains("c"))
        val row2 = qr.next()
        assert(row2.getString("constraint_name").contains("unq_foo2"))
        assert(row2.getString("constraint_type").contains("u"))
        assert(!qr.hasNext, "The function returned more than 2 results")
      }
  }

}
