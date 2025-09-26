//
//  FDCCacheService.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/25/25.
//

import Foundation

// MARK: - Cache Stats

struct CacheStats {
    let searchCount: Int
    let detailCount: Int
    let totalSize: Int
}

// MARK: - Cache Configuration

struct CacheConfiguration {
    let maxAge: TimeInterval
    let maxSize: Int

    static let `default` = CacheConfiguration(
        maxAge: 7 * 24 * 60 * 60, // 7 days
        maxSize: 1000 // Maximum number of cached items
    )
}

// MARK: - Cache Entry

private struct CacheEntry<T: Codable>: Codable {
    let data: T
    let timestamp: Date
    let accessCount: Int

    init(data: T) {
        self.data = data
        timestamp = Date()
        accessCount = 1
    }

    func accessed() -> CacheEntry<T> {
        CacheEntry(
            data: data,
            timestamp: timestamp,
            accessCount: accessCount + 1
        )
    }

    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > CacheConfiguration.default.maxAge
    }
}

// MARK: - Cache Service

@MainActor
final class FDCCacheService: ObservableObject {
    private var searchCache: [String: CacheEntry<[FDCFoodSummary]>] = [:]
    private var detailCache: [Int: CacheEntry<ProxyFoodDetailResponse>] = [:]
    private let configuration: CacheConfiguration

    init(configuration: CacheConfiguration = .default) {
        self.configuration = configuration
    }

    // MARK: - Search Cache

    func cachedSearchResults(for query: String) -> [FDCFoodSummary]? {
        let key = normalizedQuery(query)
        guard let entry = searchCache[key], !entry.isExpired else {
            searchCache.removeValue(forKey: key)
            return nil
        }

        searchCache[key] = entry.accessed()
        return entry.data
    }

    func cacheSearchResults(_ results: [FDCFoodSummary], for query: String) {
        let key = normalizedQuery(query)
        searchCache[key] = CacheEntry(data: results)
        cleanupIfNeeded()
    }

    // MARK: - Detail Cache

    func cachedFoodDetails(for fdcId: Int) -> ProxyFoodDetailResponse? {
        guard let entry = detailCache[fdcId], !entry.isExpired else {
            detailCache.removeValue(forKey: fdcId)
            return nil
        }

        detailCache[fdcId] = entry.accessed()
        return entry.data
    }

    func cacheFoodDetails(_ details: ProxyFoodDetailResponse, for fdcId: Int) {
        detailCache[fdcId] = CacheEntry(data: details)
        cleanupIfNeeded()
    }

    // MARK: - Cache Management

    func clearCache() {
        searchCache.removeAll()
        detailCache.removeAll()
    }

    func clearExpiredEntries() {
        searchCache = searchCache.filter { !$0.value.isExpired }
        detailCache = detailCache.filter { !$0.value.isExpired }
    }

    var cacheStats: CacheStats {
        CacheStats(
            searchCount: searchCache.count,
            detailCount: detailCache.count,
            totalSize: searchCache.count + detailCache.count
        )
    }

    // MARK: - Private Helpers

    private func normalizedQuery(_ query: String) -> String {
        query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func cleanupIfNeeded() {
        let totalSize = searchCache.count + detailCache.count
        guard totalSize > configuration.maxSize else { return }

        // Remove least recently accessed entries
        let searchEntries = searchCache.sorted { $0.value.accessCount < $1.value.accessCount }
        let detailEntries = detailCache.sorted { $0.value.accessCount < $1.value.accessCount }

        let entriesToRemove = totalSize - configuration.maxSize
        let searchToRemove = min(entriesToRemove / 2, searchEntries.count)
        let detailToRemove = min(entriesToRemove - searchToRemove, detailEntries.count)

        for index in 0 ..< searchToRemove {
            searchCache.removeValue(forKey: searchEntries[index].key)
        }

        for index in 0 ..< detailToRemove {
            detailCache.removeValue(forKey: detailEntries[index].key)
        }
    }
}
