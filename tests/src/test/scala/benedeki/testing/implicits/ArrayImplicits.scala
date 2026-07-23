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

import za.co.absa.db.balta.classes.setter.CustomDBType

import scala.language.implicitConversions

object ArrayImplicits {
  implicit class StringArrayEnhancements(val strings: Array[String]) extends AnyVal {
    def toDbType: CustomDBType = {
      val value = strings.map('"' + _ + '"').mkString("{",",","}")
      CustomDBType(value , "TEXT[]")
    }
  }
}
