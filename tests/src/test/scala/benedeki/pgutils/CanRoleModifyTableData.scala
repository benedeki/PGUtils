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

import za.co.absa.db.balta.DBTestSuite
import benedeki.testing.implicits.DBFunctionImplicits.DBFunctionEnhancements
import benedeki.testing.ExtraFunctions._


class CanRoleModifyTableData extends DBTestSuite {

  test("Owner can modify table data") {
    val result = function("pgutils.can_role_modify_table_data")
      .setParam("i_role_name", "pgutils_owner")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table1")
      .callFunction()
      .getBoolean("can_modify").get
    assert(result)
  }

  test("Superuser can modify table data") {
    val result = function("pgutils.can_role_modify_table_data")
      .setParam("i_role_name", "postgres")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table1")
      .callFunction()
      .getBoolean("can_modify").get
    assert(result)
  }

  test("Role with INSERT, UPDATE and DELETE grants can modify table data") {
    ddl("GRANT INSERT, UPDATE, DELETE ON pgutils_testing.table2 TO pgutils_owner;")
    val result = function("pgutils.can_role_modify_table_data")
      .setParam("i_role_name", "pgutils_owner")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table1")
      .callFunction()
      .getBoolean("can_modify").get
    assert(result)
  }

  test("Role with only TRUNCATE grant can modify table data") {
    ddl("GRANT TRUNCATE ON pgutils_testing.table2 TO pgutils_owner;")

    val result = function("pgutils.can_role_modify_table_data")
      .setParam("i_role_name", "pgutils_owner")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table2")
      .callFunction()
      .getBoolean("can_modify").get
    assert(result)
  }

  test("Role with no DML grants cannot modify table data") {
    val result = function("pgutils.can_role_modify_table_data")
      .setParam("i_role_name", "pgutils_tester")
      .setParam("i_schema_name", "pgutils")
      .setParam("i_table_name", "active_mutexes")
      .callFunction()
      .getBoolean("can_modify").get
    assert(!result)
  }

  test("Role with only SELECT grant cannot modify table data") {
    ddl("GRANT SELECT ON pgutils_testing.table2 TO PUBLIC;")

    val result = function("pgutils.can_role_modify_table_data")
      .setParam("i_role_name", "pgutils")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table2")
      .callFunction()
      .getBoolean("can_modify").get
    // NB: this only holds if pgutils_tester's INSERT/UPDATE/DELETE grants on table2 have not been
    // established by another test/fixture; see note below.
    assert(!result)
  }

  test("Non-existing role cannot modify table data") {
    val result = function("pgutils.can_role_modify_table_data")
      .setParam("i_role_name", "role_that_does_not_exist")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table1")
      .callFunction()
      .getBoolean("can_modify").get
    assert(!result)
  }

  test("Default i_role_name checks the session user") {
    val result = function("pgutils.can_role_modify_table_data")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table1")
      .callFunction()
      .getBoolean("can_modify").get
    assert(result)
  }

}
