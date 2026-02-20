package com.bkes994408.expensetrackernative.network

interface NetworkClient {
    suspend fun get(path: String): String
}

class StubNetworkClient : NetworkClient {
    override suspend fun get(path: String): String {
        return "{}"
    }
}
