import Foundation

struct CacheEntry<T: Codable>: Codable {
    let cachedAt: Date
    let data: T
}

private struct CacheMetadata: Codable {
    let cachedAt: Date
}

/// Protocol for caching avalanche warning data as JSON files.
///
/// All operations are best-effort — loads return `nil` on miss,
/// saves silently swallow errors. Cache is a performance optimization,
/// not a source of truth.
protocol CacheServiceProtocol: Sendable {
    /// Load cached region summaries for a country, or `nil` if no cache exists.
    func loadRegions(country: Country) async -> [RegionSummary]?

    /// Save region summaries to disk for the given country.
    func saveRegions(_ regions: [RegionSummary], country: Country) async

    /// Load cached detailed warnings for a region, or `nil` if no cache exists.
    func loadWarningsDetailed(regionId: Int) async -> [AvalancheWarningDetailed]?

    /// Save detailed warnings to disk for the given region.
    func saveWarningsDetailed(_ warnings: [AvalancheWarningDetailed], regionId: Int) async

    /// Returns `true` if the region cache for the given country is less than 4 hours old.
    func isFresh(country: Country) async -> Bool

    /// Returns `true` if the warning cache for the given region is less than 4 hours old.
    func isWarningFresh(regionId: Int) async -> Bool

    /// Remove all cached files.
    func clearAll() async
}

/// File-based JSON cache stored in `{cachesDirectory}/iVarsom/`.
///
/// Uses the OS caches directory so the system can evict files under storage pressure.
/// Files are written atomically to prevent corruption. Dates are encoded using the
/// Varsom date format for consistency with the API layer.
actor CacheService: CacheServiceProtocol {
    private static let maxAge: TimeInterval = 4 * 60 * 60 // 4 hours

    private let cacheDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private let now: @Sendable () -> Date

    init(directory: URL? = nil, now: @escaping @Sendable () -> Date = { Date.current }) {
        self.cacheDirectory = directory ?? URL.cachesDirectory.appendingPathComponent("iVarsom", isDirectory: true)
        self.now = now

        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .formatted(Formatter.varsomDate)

        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .varsomDate
    }

    func loadRegions(country: Country) -> [RegionSummary]? {
        return load(from: regionsFileName(country: country))
    }

    func saveRegions(_ regions: [RegionSummary], country: Country) {
        save(regions, to: regionsFileName(country: country))
    }

    func loadWarningsDetailed(regionId: Int) -> [AvalancheWarningDetailed]? {
        return load(from: warningsFileName(regionId: regionId))
    }

    func saveWarningsDetailed(_ warnings: [AvalancheWarningDetailed], regionId: Int) {
        save(warnings, to: warningsFileName(regionId: regionId))
    }

    func isFresh(country: Country) -> Bool {
        return checkFreshness(of: regionsFileName(country: country))
    }

    func isWarningFresh(regionId: Int) -> Bool {
        return checkFreshness(of: warningsFileName(regionId: regionId))
    }

    func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }

    // MARK: - Private

    private func regionsFileName(country: Country) -> String {
        switch country {
        case .norway: return "regions_norway.json"
        case .sweden: return "regions_sweden.json"
        }
    }

    private func warningsFileName(regionId: Int) -> String {
        return "warnings_\(regionId).json"
    }

    private func fileURL(for fileName: String) -> URL {
        return cacheDirectory.appendingPathComponent(fileName)
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private func save<T: Codable>(_ data: T, to fileName: String) {
        ensureDirectoryExists()
        let entry = CacheEntry(cachedAt: now(), data: data)
        guard let jsonData = try? encoder.encode(entry) else { return }
        try? jsonData.write(to: fileURL(for: fileName), options: .atomic)
    }

    private func load<T: Codable>(from fileName: String) -> T? {
        guard let data = try? Data(contentsOf: fileURL(for: fileName)) else { return nil }
        let entry = try? decoder.decode(CacheEntry<T>.self, from: data)
        return entry?.data
    }

    private func checkFreshness(of fileName: String) -> Bool {
        guard let data = try? Data(contentsOf: fileURL(for: fileName)) else { return false }
        guard let metadata = try? decoder.decode(CacheMetadata.self, from: data) else { return false }
        let age = now().timeIntervalSince(metadata.cachedAt)
        return age >= 0 && age < Self.maxAge
    }
}
