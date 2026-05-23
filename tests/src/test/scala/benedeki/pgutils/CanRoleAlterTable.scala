package benedeki.pgutils

import za.co.absa.db.balta.DBTestSuite
import benedeki.testing.implicits.DBFunctionImplicits.DBFunctionEnhancements
import benedeki.testing.ExtraFunctions._


class CanRoleAlterTable extends DBTestSuite{


  test("Owner can alter table") {
    val result = function("pgutils.can_role_alter_table")
      .setParam("i_role_name", "pgutils_owner")
      .setParam("i_schema_name", "pgutils")
      .setParam("i_table_name", "active_mutexes")
      .callFunction()
      .getBoolean("can_alter").get
    assert(result)
  }

  test("Superuser can alter table") {
    val result = function("pgutils.can_role_alter_table")
      .setParam("i_role_name", "postgres")
      .setParam("i_schema_name", "pgutils")
      .setParam("i_table_name", "active_mutexes")
      .callFunction()
      .getBoolean("can_alter").get
    assert(result)
  }

  test("User with no permissions cannot alter table") {
    val result = function("pgutils.can_role_alter_table")
      .setParam("i_role_name", "pgutils_tester")
      .setParam("i_schema_name", "pgutils")
      .setParam("i_table_name", "active_mutexes")
      .callFunction()
      .getBoolean("can_alter").get
    assert(!result)
  }

  ignore("User with parent role can alter table") {
    val tableName = "fooooooo"
    ddl("CREATE ROLE parent_owner INHERIT;")
    ddl(s"CREATE TABLE pgutils.$tableName (bar TEXT);")
    ddl(s"ALTER TABLE pgutils.$tableName OWNER to parent_owner;")
    val result = function("pgutils.can_role_alter_table")
      .setParam("i_role_name", "pgutils_tester")
      .setParam("i_schema_name", "pgutils")
      .setParam("i_table_name", "active_mutexes")
      .callFunction()
      .getBoolean("can_alter").get
    assert(result)
  }

}
