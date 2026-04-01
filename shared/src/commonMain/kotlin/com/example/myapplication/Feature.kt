package com.example.myapplication

import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlin.time.Duration.Companion.seconds

sealed class FeatureState {
    data object Idle : FeatureState()
    data object Loading : FeatureState()
    data class Success(val data: String) : FeatureState()
    data class Error(val message: String) : FeatureState()
}

class FeatureRepository {
    // Simulate a one-shot API call
    suspend fun fetchData(): String {
        delay(2000) // Simulate network delay
        return "Hello from Kotlin (One-Shot)!"
    }

    // Simulate a real-time data stream
    val dataStream: Flow<FeatureState> = flow {
        emit(FeatureState.Idle)
        delay(1.seconds)
        emit(FeatureState.Loading)
        delay(2.seconds)
        emit(FeatureState.Success("Stream Item 1"))
        delay(2.seconds)
        emit(FeatureState.Success("Stream Item 2"))
        delay(2.seconds)
        emit(FeatureState.Error("Something went wrong!"))
    }
}
