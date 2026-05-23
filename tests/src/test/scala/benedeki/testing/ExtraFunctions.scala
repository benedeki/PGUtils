package benedeki.testing

import za.co.absa.db.balta.classes.DBConnection

object ExtraFunctions {
  def ddl(sql: String)(implicit connection: DBConnection): Unit = {
    val stmt = connection.connection.createStatement()
    stmt.executeUpdate(sql)
  }

  def dml(sql: String)(implicit connection: DBConnection): Unit = {
    val stmt = connection.connection.createStatement()
    stmt.executeUpdate(sql)
  }
}
