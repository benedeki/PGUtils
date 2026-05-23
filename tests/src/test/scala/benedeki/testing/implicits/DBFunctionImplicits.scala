package benedeki.testing.implicits

import za.co.absa.db.balta.classes.{DBConnection, DBFunction, QueryResultRow}

object DBFunctionImplicits {
  implicit class DBFunctionEnhancements(val dbFunction: DBFunction) extends AnyVal{
    def callFunction()(implicit connection: DBConnection): QueryResultRow = {
      dbFunction.execute{qr =>
        assert(qr.hasNext, "The function did not return any result")
        val result = qr.next()
        assert(!qr.hasNext, "The function returned more than one result")
        result
      }
    }
  }
}
