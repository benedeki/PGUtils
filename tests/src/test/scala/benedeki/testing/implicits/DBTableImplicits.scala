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

package benedeki.testing.implicits

import za.co.absa.db.balta.classes.{DBConnection, DBTable, QueryResultRow}
import za.co.absa.db.balta.classes.setter.{AllowedParamTypes, Params}

object DBTableImplicits {
  implicit class DBTableEnhancements(val table: DBTable) extends AnyVal {
    def insert[A: AllowedParamTypes, B: AllowedParamTypes, C: AllowedParamTypes](
               field1: (String, A), field2: (String, B), field3: (String, C))
              (implicit connection: DBConnection): QueryResultRow = {
      table.insert(
        Params.add(field1._1, field1._2)
        .add(field2._1, field2._2)
        .add(field3._1, field3._2))
    }
  }
}
