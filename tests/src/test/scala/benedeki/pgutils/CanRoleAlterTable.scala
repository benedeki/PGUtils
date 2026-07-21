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
