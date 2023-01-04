import AppIntents

struct RegionQuery: EntityQuery {
  func entities(for identifiers: [RegionOption.ID]) async throws -> [RegionOption] {
      return RegionOption.aRegions.filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [RegionOption] {
      return RegionOption.aRegions
  }
}
