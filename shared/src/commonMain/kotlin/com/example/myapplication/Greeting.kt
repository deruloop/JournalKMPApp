package com.example.myapplication

class Greeting {
    private val platform = getPlatform()

    fun greet(): String {
        return "Hello, ${platform.name}!"
    }

    fun formatName(name: String): String {
        return "Formatted Name: [${name.uppercase()}]"
    }
}