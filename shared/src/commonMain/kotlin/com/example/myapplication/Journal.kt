package com.example.myapplication

import com.example.myapplication.db.AppDatabase
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.datetime.Clock
import kotlinx.serialization.Serializable
import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO

// We can keep the data class if we want to map to it, or just use the generated one.
// The generated one will be named JournalEntry too.
// Let's alias the generated one or just remove this one and use the generated one.
// Since the generated one is in com.example.myapplication.db, we can use that.
// But to minimize changes in iOS, let's map it.

@Serializable
data class JournalEntryModel(
    val id: String,
    val dateIso: String,
    val mood: String,
    val note: String
)

class JournalRepository(databaseDriverFactory: DatabaseDriverFactory) {
    private val database = AppDatabase(databaseDriverFactory.createDriver())
    private val dbQueries = database.journalQueries

    val entries: Flow<List<JournalEntryModel>> = dbQueries.selectAll()
        .asFlow()
        .mapToList(Dispatchers.IO)
        .map { list ->
            list.map { JournalEntryModel(it.id, it.dateIso, it.mood, it.note) }
        }

    @Throws(Exception::class) // For Swift
    suspend fun addEntry(mood: String, note: String) {
        val currentMoment = Clock.System.now()
        val dateIso = currentMoment.toString()
        val id = currentMoment.toEpochMilliseconds().toString()
        
        dbQueries.insertItem(id, dateIso, mood, note)
    }

    @Throws(Exception::class)
    suspend fun deleteEntry(id: String) {
        dbQueries.deleteItem(id)
    }
}

object JournalFactory {
    fun createRepository(driverFactory: DatabaseDriverFactory): JournalRepository {
        return JournalRepository(driverFactory)
    }
}
