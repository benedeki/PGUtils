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

class LogToConsole extends DBTestSuite{
  test("Syntax check with default parameter for timestamp") {
    val logToConsole = function("pgutils.log_to_console").setParam("Hello world!")
    logToConsole.perform()
  }

  test("Syntax check with timestamp off") {
    val logToConsole = function("pgutils.log_to_console")
      .setParam("Hello world!")
      .setParam(false)
    logToConsole.perform()
  }

}
