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

import Dependencies.*
import sbt.Keys.libraryDependencies

ThisBuild / scalaVersion     := "3.8.4"
ThisBuild / version          := "0.1.0"
ThisBuild / organization     := "benedeki"
ThisBuild / organizationName := "David Benedeki"

ThisBuild / developers := List(
  Developer(
    id    = "benedeki",
    name  = "David Benedeki",
    email = "",
    url   = url("https://github.com/benedeki")
  )
)

ThisBuild / description := "Testing routines for the PGUtils library"
ThisBuild / startYear := Some(2026)
ThisBuild / licenses += "Apache-2.0" -> url("https://www.apache.org/licenses/LICENSE-2.0.txt")
ThisBuild / homepage := Some(url("https://github.com/benedeki/PGUtils"))
ThisBuild / organizationHomepage := Some(url("https://github.com/benedeki"))


lazy val root = (project in file("tests"))
  .settings(
    name := "pgutils - tests",
    libraryDependencies ++= databaseDependencies,
  )

