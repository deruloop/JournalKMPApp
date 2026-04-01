package com.example.myapplication.db

import app.cash.sqldelight.Query
import app.cash.sqldelight.TransacterImpl
import app.cash.sqldelight.db.SqlDriver
import kotlin.Any
import kotlin.String

public class JournalQueries(
  driver: SqlDriver,
) : TransacterImpl(driver) {
  public fun <T : Any> selectAll(mapper: (
    id: String,
    dateIso: String,
    mood: String,
    note: String,
  ) -> T): Query<T> = Query(-1_347_043_103, arrayOf("JournalEntry"), driver, "Journal.sq",
      "selectAll", """
  |SELECT JournalEntry.id, JournalEntry.dateIso, JournalEntry.mood, JournalEntry.note
  |FROM JournalEntry
  |ORDER BY dateIso DESC
  """.trimMargin()) { cursor ->
    mapper(
      cursor.getString(0)!!,
      cursor.getString(1)!!,
      cursor.getString(2)!!,
      cursor.getString(3)!!
    )
  }

  public fun selectAll(): Query<JournalEntry> = selectAll { id, dateIso, mood, note ->
    JournalEntry(
      id,
      dateIso,
      mood,
      note
    )
  }

  public fun insertItem(
    id: String,
    dateIso: String,
    mood: String,
    note: String,
  ) {
    driver.execute(-481_262_832, """
        |INSERT OR REPLACE INTO JournalEntry(id, dateIso, mood, note)
        |VALUES (?, ?, ?, ?)
        """.trimMargin(), 4) {
          bindString(0, id)
          bindString(1, dateIso)
          bindString(2, mood)
          bindString(3, note)
        }
    notifyQueries(-481_262_832) { emit ->
      emit("JournalEntry")
    }
  }

  public fun deleteItem(id: String) {
    driver.execute(317_160_706, """
        |DELETE FROM JournalEntry
        |WHERE id = ?
        """.trimMargin(), 1) {
          bindString(0, id)
        }
    notifyQueries(317_160_706) { emit ->
      emit("JournalEntry")
    }
  }

  public fun deleteAll() {
    driver.execute(10_223_058, """DELETE FROM JournalEntry""", 0)
    notifyQueries(10_223_058) { emit ->
      emit("JournalEntry")
    }
  }
}
