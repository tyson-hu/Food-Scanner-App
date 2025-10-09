<!-- 0a88ba18-53bf-464e-9338-42b119834fd9 563c38c1-338f-4161-9bce-a8f66943794e -->
# Calry v0.4.0 — Foundation Implementation Plan (Scoped for 0.4.0 Promises)

## Scope Summary

**In Scope (Phase 1 Foundation):**

- All 4 models: FoodRef, enhanced FoodEntry, UserFoodPrefs, RecentFood
- Basic portion conversion (g/ml/serving + household when grams known)
- SnapshotNutrientCalculator (portion → grams → snap* nutrients)
- DVCalculator (%DV rendering helper)
- Minimal Quick Add/History services (write on log, read top N)
- Basic repository CRUD + simple queries
- Comprehensive model + critical service tests

**Out of Scope:**

- Visual portion guides, AI suggestions, meal bundles
- Full micronutrient coaching/targets
- Generic cup↔gram conversions without source data
- Advanced ranking/filtering (Phase 2 polish)

## Current State

**Existing:**

- `FoodEntry` with basic fields (name, brand, fdcId, quantity, unit, calories, protein, fat, carbs)
- `FoodCard` and `FoodDetails` API models (new names for MinimalCard/AuthoritativeDetail)
- `FoodEntryBuilder` for basic conversion
- Basic `FoodLogRepository` protocol

**API Models Updated:**

- `FoodMinimalCard` → `FoodCard`
- `FoodAuthoritativeDetail` → `FoodDetails`

## Phase 1A: Core Types & Enums

### Create: `Sources/Models/Core/FoodLogging/FoodLoggingTypes.swift`

```swift
// Unit enum with household support
public enum Unit: Sendable, Codable, Equatable, Hashable {
    case g
    case ml
    case serving
    case household(label: String)
    
    var displayName: String {
        switch self {
        case .g: return "g"
        case .ml: return "ml"
        case .serving: return "serving"
        case .household(let label): return label
        }
    }
}

// Meal type enum
public enum Meal: String, Sendable, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
}

// Entry kind (catalog vs manual)
public enum EntryKind: String, Sendable, Codable {
    case catalog
    case manual
}

// Household unit metadata (from API portions)
public struct HouseholdUnit: Sendable, Codable, Equatable, Hashable {
    public let label: String    // e.g., "1 can", "1 slice"
    public let grams: Double     // resolved mass in grams
    
    public init(label: String, grams: Double) {
        self.label = label
        self.grams = grams
    }
}

// Label nutrients (sparse, nil = missing ≠ zero)
public struct LabelNutrients: Sendable, Codable, Equatable {
    public let energyKcal: Double?
    public let protein: Double?
    public let fat: Double?
    public let saturatedFat: Double?
    public let carbs: Double?
    public let fiber: Double?
    public let sugars: Double?
    public let addedSugars: Double?
    public let sodium: Double?
    public let cholesterol: Double?
    
    public init(
        energyKcal: Double? = nil,
        protein: Double? = nil,
        fat: Double? = nil,
        saturatedFat: Double? = nil,
        carbs: Double? = nil,
        fiber: Double? = nil,
        sugars: Double? = nil,
        addedSugars: Double? = nil,
        sodium: Double? = nil,
        cholesterol: Double? = nil
    ) {
        self.energyKcal = energyKcal
        self.protein = protein
        self.fat = fat
        self.saturatedFat = saturatedFat
        self.carbs = carbs
        self.fiber = fiber
        self.sugars = sugars
        self.addedSugars = addedSugars
        self.sodium = sodium
        self.cholesterol = cholesterol
    }
}
```

### Test: `Tests/Unit/Models/FoodLoggingTypesTests.swift`

- Test Unit enum codable (especially .household with labels)
- Test Meal enum cases and rawValues
- Test EntryKind cases
- Test HouseholdUnit init and equality
- Test LabelNutrients with nil vs 0 (nil stays nil, 0 is explicit)

## Phase 1B: FoodRef Model (Catalog)

### Create: `Sources/Models/Core/FoodRef.swift`

```swift
import Foundation
import SwiftData

@Model
public final class FoodRef {
    @Attribute(.unique) public var gid: String  // "fdc:123" or "off:0123456789012"
    public var source: SourceTag                // .fdc or .off (reuse existing)
    public var name: String
    public var brand: String?
    
    // Serving metadata
    public var servingSize: Double?             // from FoodServing.amount
    public var servingSizeUnit: String?         // from FoodServing.unit
    public var gramsPerServing: Double?         // calculated or from portions
    
    // Household units (encoded as Data)
    public var householdUnitsData: Data?        // [HouseholdUnit] encoded
    
    // Label nutrients (sparse, encoded as Data)
    public var labelNutrientsData: Data?        // LabelNutrients encoded
    
    // Metadata
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(
        gid: String,
        source: SourceTag,
        name: String,
        brand: String? = nil,
        servingSize: Double? = nil,
        servingSizeUnit: String? = nil,
        gramsPerServing: Double? = nil,
        householdUnits: [HouseholdUnit]? = nil,
        labelNutrients: LabelNutrients? = nil
    ) {
        self.gid = gid
        self.source = source
        self.name = name
        self.brand = brand
        self.servingSize = servingSize
        self.servingSizeUnit = servingSizeUnit
        self.gramsPerServing = gramsPerServing
        self.createdAt = Date()
        self.updatedAt = Date()
        
        // Encode complex types to Data
        if let units = householdUnits {
            self.householdUnitsData = try? JSONEncoder().encode(units)
        }
        if let nutrients = labelNutrients {
            self.labelNutrientsData = try? JSONEncoder().encode(nutrients)
        }
    }
    
    // Computed properties for easy access
    public var householdUnits: [HouseholdUnit]? {
        get {
            guard let data = householdUnitsData else { return nil }
            return try? JSONDecoder().decode([HouseholdUnit].self, from: data)
        }
        set {
            householdUnitsData = newValue.flatMap { try? JSONEncoder().encode($0) }
            updatedAt = Date()
        }
    }
    
    public var labelNutrients: LabelNutrients? {
        get {
            guard let data = labelNutrientsData else { return nil }
            return try? JSONDecoder().decode(LabelNutrients.self, from: data)
        }
        set {
            labelNutrientsData = newValue.flatMap { try? JSONEncoder().encode($0) }
            updatedAt = Date()
        }
    }
}
```

### Test: `Tests/Unit/Models/FoodRefTests.swift`

- Test FoodRef initialization with all fields
- Test householdUnits encoding/decoding roundtrip
- Test labelNutrients encoding/decoding roundtrip
- Test gid uniqueness constraint (SwiftData)
- Test computed properties (get/set householdUnits, labelNutrients)

## Phase 1C: Enhanced FoodEntry Model

### Update: `Sources/Models/Core/LoggedFoodEntry.swift`

Add new fields to existing FoodEntry (keep old fields for migration):

```swift
@Model
public final class FoodEntry {
    // Existing fields (keep for backward compatibility)
    public var id = UUID()
    var date = Date()
    var name: String
    var brand: String?
    var fdcId: Int?
    var quantity: Double = 1.0
    var unit: String = "serving"
    var servingDescription: String = "1 serving"
    var resolvedToBase: Double = 100.0
    var baseUnit: String = "g"
    var calories: Double = 0.0
    var protein: Double = 0.0
    var fat: Double = 0.0
    var carbs: Double = 0.0
    var nutrientsSnapshot: [String: Double] = [:]
    
    // NEW FIELDS FOR 0.4.0
    public var kind: EntryKind = .catalog
    public var foodGID: String?              // Link to FoodRef
    public var customName: String?           // For manual entries
    public var meal: Meal = .lunch           // Default meal
    public var gramsResolved: Double?        // Actual grams when known
    public var note: String?                 // Optional user note
    
    // Snapshot nutrients (optionals: nil = missing, not zero)
    public var snapEnergyKcal: Double?
    public var snapProtein: Double?
    public var snapFat: Double?
    public var snapSaturatedFat: Double?
    public var snapCarbs: Double?
    public var snapFiber: Double?
    public var snapSugars: Double?
    public var snapSodium: Double?
    public var snapCholesterol: Double?
    
    // Keep existing init, add new init for 0.4.0
}
```

### Test: `Tests/Unit/Models/FoodEntryTests.swift`

- Test FoodEntry with catalog kind + foodGID
- Test FoodEntry with manual kind + customName
- Test meal type assignment
- Test gramsResolved calculation
- Test snapshot nutrients (nil vs 0 distinction)
- Test backward compatibility with existing fields

## Phase 1D: UserFoodPrefs Model

### Create: `Sources/Models/Core/UserFoodPrefs.swift`

```swift
import Foundation
import SwiftData

@Model
public final class UserFoodPrefs {
    public var userId: String               // For future multi-user (use "default" for now)
    public var foodGID: String              // Link to FoodRef
    public var defaultUnitRaw: String       // Unit enum encoded
    public var defaultQty: Double
    public var defaultMealRaw: String       // Meal enum encoded
    public var updatedAt: Date
    
    public init(
        userId: String = "default",
        foodGID: String,
        defaultUnit: Unit,
        defaultQty: Double,
        defaultMeal: Meal
    ) {
        self.userId = userId
        self.foodGID = foodGID
        self.defaultUnitRaw = encodeUnit(defaultUnit)
        self.defaultQty = defaultQty
        self.defaultMealRaw = defaultMeal.rawValue
        self.updatedAt = Date()
    }
    
    // Computed properties
    public var defaultUnit: Unit {
        get { decodeUnit(defaultUnitRaw) }
        set { defaultUnitRaw = encodeUnit(newValue); updatedAt = Date() }
    }
    
    public var defaultMeal: Meal {
        get { Meal(rawValue: defaultMealRaw) ?? .lunch }
        set { defaultMealRaw = newValue.rawValue; updatedAt = Date() }
    }
    
    // Helper methods for Unit encoding (since it has associated values)
    private func encodeUnit(_ unit: Unit) -> String {
        switch unit {
        case .g: return "g"
        case .ml: return "ml"
        case .serving: return "serving"
        case .household(let label): return "household:\(label)"
        }
    }
    
    private func decodeUnit(_ raw: String) -> Unit {
        if raw == "g" { return .g }
        if raw == "ml" { return .ml }
        if raw == "serving" { return .serving }
        if raw.hasPrefix("household:") {
            let label = String(raw.dropFirst("household:".count))
            return .household(label: label)
        }
        return .serving // fallback
    }
}
```

### Test: `Tests/Unit/Models/UserFoodPrefsTests.swift`

- Test preference storage per user/food
- Test default portion recall
- Test meal preference tracking
- Test Unit encoding/decoding (especially .household)
- Test upsert behavior (update existing or create new)

## Phase 1E: RecentFood Model

### Create: `Sources/Models/Core/RecentFood.swift`

```swift
import Foundation
import SwiftData

@Model
public final class RecentFood {
    public var userId: String = "default"
    public var foodGID: String
    public var lastUsedAt: Date
    public var useCount: Int = 1
    public var isFavorite: Bool = false
    
    public init(
        userId: String = "default",
        foodGID: String,
        lastUsedAt: Date = Date(),
        useCount: Int = 1,
        isFavorite: Bool = false
    ) {
        self.userId = userId
        self.foodGID = foodGID
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
        self.isFavorite = isFavorite
    }
    
    // Scoring: 70% recency + 30% frequency
    public var score: Double {
        let recencyWeight = 0.7
        let frequencyWeight = 0.3
        
        let daysSinceUse = Date().timeIntervalSince(lastUsedAt) / 86400.0
        let recencyScore = max(0, 1.0 - (daysSinceUse / 90.0))  // 90-day window
        let frequencyScore = min(1.0, Double(useCount) / 50.0)  // cap at 50 uses
        
        return recencyScore * recencyWeight + frequencyScore * frequencyWeight
    }
}
```

### Test: `Tests/Unit/Models/RecentFoodTests.swift`

- Test recent food creation
- Test usage frequency updates
- Test scoring algorithm (70% recency + 30% frequency)
- Test 90-day window (score → 0 after 90 days)
- Test favorite flag toggling
- Test score comparison for sorting

## Phase 2: Services Layer (Essential Only)

### Phase 2A: Portion Resolver (Basic)

### Create: `Sources/Services/Data/Processing/PortionResolver.swift`

Basic unit conversion ONLY when grams are known from source:

```swift
public struct PortionResolver {
    // Convert standard units
    static func convertMass(amount: Double, from: MassUnit, to: MassUnit) -> Double
    static func convertVolume(amount: Double, from: VolumeUnit, to: VolumeUnit) -> Double
    
    // Resolve portion to grams (returns nil if not determinable)
    static func resolveToGrams(
        quantity: Double,
        unit: Unit,
        gramsPerServing: Double?,
        householdUnits: [HouseholdUnit]?
    ) -> Double?
    
    enum MassUnit { case g, kg, oz, lb }
    enum VolumeUnit { case ml, l, flOz }
}
```

### Test: `Tests/Unit/Services/PortionResolverTests.swift`

- Test mass conversion (g ↔ kg ↔ oz ↔ lb)
- Test volume conversion (ml ↔ l ↔ fl oz)
- Test serving → grams (when gramsPerServing known)
- Test household → grams (when HouseholdUnit.grams available)
- Test returns nil when grams unknown (no guessing)
- Test water approximation for beverages (1ml ≈ 1g) - ONLY when baseUnit is ml

### Phase 2B: Snapshot Nutrient Calculator

### Create: `Sources/Services/Data/Processing/SnapshotNutrientCalculator.swift`

Critical service for computing snap* nutrients from FoodRef + portion:

```swift
@MainActor
public struct SnapshotNutrientCalculator {
    // Calculate snapshot nutrients from FoodRef per100Base + resolved grams
    static func calculateSnapshot(
        foodRef: FoodRef,
        quantity: Double,
        unit: Unit
    ) -> (
        energyKcal: Double?,
        protein: Double?,
        fat: Double?,
        saturatedFat: Double?,
        carbs: Double?,
        fiber: Double?,
        sugars: Double?,
        sodium: Double?,
        cholesterol: Double?
    )
}
```

### Test: `Tests/Unit/Services/SnapshotNutrientCalculatorTests.swift`

- Test snapshot calculation from per100Base nutrients
- Test portion scaling (2 servings = 2× nutrients)
- Test missing nutrients stay nil (not 0)
- Test zero nutrients stay 0 (explicit)
- Test different unit conversions (g, ml, serving, household)

### Phase 2C: DV Calculator

### Create: `Sources/Services/Data/Processing/DVCalculator.swift`

Render-time helper for %DV calculations:

```swift
public struct DVConstants {
    static let energy: Double = 2000        // kcal
    static let protein: Double = 50         // g
    static let fat: Double = 78             // g
    static let saturatedFat: Double = 20    // g
    static let carbs: Double = 275          // g
    static let fiber: Double = 28           // g
    static let sodium: Double = 2300        // mg
    static let cholesterol: Double = 300    // mg
}

public struct DVCalculator {
    static func percentDV(for nutrient: String, amount: Double) -> Double?
}
```

### Test: `Tests/Unit/Services/DVCalculatorTests.swift`

- Test %DV calculation for each nutrient
- Test returns nil for unknown nutrients
- Test handles zero amounts
- Test handles amounts > 100% DV

### Phase 2D: FoodRef Builder

### Create: `Sources/Services/Data/Processing/FoodRefBuilder.swift`

Convert API models to FoodRef:

```swift
public struct FoodRefBuilder {
    static func from(foodCard: FoodCard) -> FoodRef
    static func from(foodDetails: FoodDetails) -> FoodRef
    
    // Helper: Extract household units from FoodPortion[]
    private static func extractHouseholdUnits(_ portions: [FoodPortion]?) -> [HouseholdUnit]?
    
    // Helper: Extract label nutrients from per100Base or labelNutrients
    private static func extractLabelNutrients(from foodCard: FoodCard) -> LabelNutrients?
}
```

### Test: `Tests/Unit/Services/FoodRefBuilderTests.swift`

- Test FoodCard → FoodRef conversion
- Test FoodDetails → FoodRef conversion
- Test household units extraction from portions (when massG available)
- Test label nutrients extraction (preserve nil for missing)
- Test gramsPerServing calculation

### Phase 2E: Enhanced FoodEntry Builder

### Update: `Sources/Services/Data/Persistence/Models/LoggedFoodEntryBuilder.swift`

Add new builder methods:

```swift
public struct FoodEntryBuilder {
    // New: Build from FoodRef
    static func from(
        foodRef: FoodRef,
        quantity: Double,
        unit: Unit,
        meal: Meal,
        at date: Date = .now
    ) -> FoodEntry
    
    // New: Build manual entry
    static func manual(
        name: String,
        energyKcal: Double,
        protein: Double?,
        fat: Double?,
        carbs: Double?,
        meal: Meal,
        at date: Date = .now
    ) -> FoodEntry
    
    // Keep existing methods for backward compatibility
}
```

### Test: `Tests/Unit/Services/EnhancedFoodEntryBuilderTests.swift`

- Test catalog entry from FoodRef
- Test manual entry creation
- Test snapshot calculation integration
- Test missing vs zero handling
- Test backward compatibility with existing builders

### Phase 2F: Quick Add Service (Minimal)

### Create: `Sources/Services/Data/QuickAddService.swift`

Minimal implementation for Phase 1:

```swift
@MainActor
public final class QuickAddService {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // Record usage (upsert RecentFood)
    func recordUsage(foodGID: String, meal: Meal) async throws
    
    // Get recent foods (top N by score)
    func recentFoods(limit: Int = 12) async throws -> [RecentFood]
    
    // Get favorites (top N by score where isFavorite)
    func favorites(limit: Int = 8) async throws -> [RecentFood]
    
    // Toggle favorite
    func toggleFavorite(foodGID: String) async throws
    
    // Prune old recents (>90 days, keep max 250)
    func pruneOldRecents() async throws
}
```

### Test: `Tests/Unit/Services/QuickAddServiceTests.swift`

- Test recordUsage creates/updates RecentFood
- Test recentFoods returns top N by score
- Test favorites returns only isFavorite items
- Test toggleFavorite changes flag
- Test pruneOldRecents removes >90 days old
- Test pruneOldRecents keeps max 250 items

### Phase 2G: Food History Service (Minimal)

### Create: `Sources/Services/Data/FoodHistoryService.swift`

```swift
@MainActor
public final class FoodHistoryService {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // Update preferences after log (or manual)
    func updatePreferences(
        foodGID: String,
        unit: Unit,
        qty: Double,
        meal: Meal
    ) async throws
    
    // Get preferences for food
    func getPreferences(foodGID: String) async throws -> UserFoodPrefs?
}
```

### Test: `Tests/Unit/Services/FoodHistoryServiceTests.swift`

- Test updatePreferences creates new UserFoodPrefs
- Test updatePreferences updates existing prefs
- Test getPreferences returns correct prefs
- Test getPreferences returns nil if not found

## Phase 3: Repository Updates

### Update: `Sources/Services/Data/Persistence/Repositories/LoggedFoodRepository.swift`

```swift
protocol FoodLogRepository: Sendable {
    func log(_ entry: FoodEntry) async throws
    func entries(on day: Date) async throws -> [FoodEntry]
    func entries(on day: Date, forMeal: Meal) async throws -> [FoodEntry]
    func totals(on day: Date) async throws -> DayTotals
    func update(_ entry: FoodEntry) async throws
    func delete(_ entry: FoodEntry) async throws
}
```

### Update: DayTotals struct

```swift
struct DayTotals: Sendable, Equatable {
    var calories: Double
    var protein: Double
    var fat: Double
    var saturatedFat: Double?
    var carbs: Double
    var fiber: Double?
    var sugars: Double?
    var sodium: Double?
    var cholesterol: Double?
}
```

### Update: `Sources/Services/Data/Persistence/Repositories/LoggedFoodRepositorySwiftData.swift`

Implement new methods.

### Test: Update existing repository tests

- Test entries by meal filtering
- Test update entry
- Test delete entry
- Test totals with new nutrients

## Phase 4: SwiftData Registration

### Update: `Sources/App/CalryApp.swift`

```swift
.modelContainer(for: [
    FoodEntry.self,
    FoodRef.self,
    UserFoodPrefs.self,
    RecentFood.self
])
```

## Integration Test

### Create: `Tests/Unit/Integration/FoodLoggingFlowTests.swift`

One end-to-end happy path:

1. Create FoodRef from FoodCard
2. Get user preferences (default if none)
3. Build FoodEntry with preferences
4. Log entry
5. Record usage in RecentFood
6. Fetch today's totals
7. Verify all data correct

## File Structure

```
Sources/Models/Core/
├── FoodLogging/
│   └── FoodLoggingTypes.swift (NEW)
├── FoodRef.swift (NEW)
├── LoggedFoodEntry.swift (UPDATE)
├── UserFoodPrefs.swift (NEW)
└── RecentFood.swift (NEW)

Sources/Services/Data/
├── Processing/
│   ├── PortionResolver.swift (NEW)
│   ├── SnapshotNutrientCalculator.swift (NEW)
│   ├── DVCalculator.swift (NEW)
│   └── FoodRefBuilder.swift (NEW)
├── Persistence/
│   ├── Models/
│   │   └── LoggedFoodEntryBuilder.swift (UPDATE)
│   └── Repositories/
│       ├── LoggedFoodRepository.swift (UPDATE)
│       └── LoggedFoodRepositorySwiftData.swift (UPDATE)
├── QuickAddService.swift (NEW)
└── FoodHistoryService.swift (NEW)

Tests/Unit/Models/
├── FoodLoggingTypesTests.swift (NEW)
├── FoodRefTests.swift (NEW)
├── FoodEntryTests.swift (NEW)
├── UserFoodPrefsTests.swift (NEW)
└── RecentFoodTests.swift (NEW)

Tests/Unit/Services/
├── PortionResolverTests.swift (NEW)
├── SnapshotNutrientCalculatorTests.swift (NEW)
├── DVCalculatorTests.swift (NEW)
├── FoodRefBuilderTests.swift (NEW)
├── EnhancedFoodEntryBuilderTests.swift (NEW)
├── QuickAddServiceTests.swift (NEW)
└── FoodHistoryServiceTests.swift (NEW)

Tests/Unit/Integration/
└── FoodLoggingFlowTests.swift (NEW)
```

## Success Criteria

- [ ] All 4 models created with SwiftData
- [ ] All 7 services implemented
- [ ] All repository methods working
- [ ] 13 test files with comprehensive coverage
- [ ] 1 integration test (happy path)
- [ ] Zero lint violations
- [ ] Zero build warnings
- [ ] All tests pass in CI
- [ ] Documentation updated

## Questions Before Implementation

1. **Unit enum Codable**: Since `.household(label)` has an associated value, should I use a custom Codable implementation or the string encoding approach shown in UserFoodPrefs?

2. **FoodRef unique constraint**: Should `gid` be the only unique constraint, or should we also enforce `(userId, foodGID)` uniqueness for UserFoodPrefs and RecentFood?

3. **SnapshotNutrientCalculator**: Should this use the existing `per100Base` nutrients from FoodCard/FoodDetails, or should it access FoodRef.labelNutrients? (I assume per100Base for accuracy)

4. **Backward compatibility**: Should the new snap *fields also populate the old calories/protein/fat/carbs fields, or should we update UI to use snap* exclusively?

5. **DVCalculator location**: Should this be in Processing or a separate UI/Helpers folder since it's render-time only?

### To-dos

- [ ] Create FoodLoggingTypes.swift with Unit, Meal, EntryKind enums and HouseholdUnit, LabelNutrients structs
- [ ] Create FoodRef SwiftData model with serving metadata and encoded complex types
- [ ] Enhance FoodEntry model with kind, meal, foodGID, gramsResolved, snap* nutrients, note
- [ ] Create UserFoodPrefs SwiftData model with Unit encoding
- [ ] Create RecentFood SwiftData model with scoring algorithm
- [ ] Create PortionResolver service for basic unit conversions
- [ ] Create SnapshotNutrientCalculator service for computing snap* nutrients
- [ ] Create DVCalculator with DVConstants for %DV rendering
- [ ] Create FoodRefBuilder to convert FoodCard/FoodDetails to FoodRef
- [ ] Enhance FoodEntryBuilder with FoodRef and manual entry support
- [ ] Create QuickAddService for recents/favorites management
- [ ] Create FoodHistoryService for preferences management
- [ ] Update FoodLogRepository protocol and implementation
- [ ] Update CalryApp to register all 4 SwiftData models
- [ ] Create end-to-end integration test for complete logging flow