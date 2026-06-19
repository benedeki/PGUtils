package benedeki.testing

import za.co.absa.db.balta.classes.DBConnection

object ExtraFunctions {
  private def execute(sql: String)(implicit connection: DBConnection): Unit = {
    val stmt = connection.connection.createStatement()
    try
      stmt.executeUpdate(sql)
    finally
      stmt.close()
  }

  def ddl(sql: String)(implicit connection: DBConnection): Unit = {
    execute(sql)
  }

  def dml(sql: String)(implicit connection: DBConnection): Unit = {
    execute(sql)
  }
}
