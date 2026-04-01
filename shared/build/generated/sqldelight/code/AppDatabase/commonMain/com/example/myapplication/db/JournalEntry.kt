package com.example.myapplication.db

import kotlin.String

public data class JournalEntry(
  public val id: String,
  public val dateIso: String,
  public val mood: String,
  public val note: String,
)
