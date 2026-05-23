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
