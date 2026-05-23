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
