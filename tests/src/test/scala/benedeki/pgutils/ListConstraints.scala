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

class ListConstraints extends DBTestSuite {
  test("List constraints returns the expected constraints") {
    function("pgutils.list_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "table1")
      .execute(orderBy = "constraint_name") { qr =>
        assert(qr.hasNext, "The function did not return any result")
        val row1 = qr.next()
        assert(row1.getString("constraint_name").contains("table1_check"))
        assert(row1.getString("constraint_type").contains("c"))
        val row2 = qr.next()
        assert(row2.getString("constraint_name").contains("table1_id_table1_not_null"))
        assert(row2.getString("constraint_type").contains("n"))
        val row3 = qr.next()
        assert(row3.getString("constraint_name").contains("table1_pkey"))
        assert(row3.getString("constraint_type").contains("p"))
        assert(!qr.hasNext, "The function returned more than 3 results")
      }
  }

  test("List constraints returns empty list for non-existing table") {
    function("pgutils.list_constraints")
      .setParam("i_schema_name", "pgutils_testing")
      .setParam("i_table_name", "nope")
      .execute { qr =>
        assert(!qr.hasNext, "The function should not return any result in schema pgutils_testing")
      }

    function("pgutils.list_constraints")
      .setParam("i_table_name", "nope")
      .execute { qr =>
        assert(!qr.hasNext, "The function should not return any result in schema public")
      }
  }

}
