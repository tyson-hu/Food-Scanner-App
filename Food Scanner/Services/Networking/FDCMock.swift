//
//  FDCMock.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//  Updated: consolidated all mock data & logic
//

import Foundation

struct FDCMock: FDCClient {
    // MARK: - New API Methods (v1 Worker API)

    func getHealth() async throws -> FoodHealthResponse {
        try? await Task.sleep(nanoseconds: 100_000_000)
        return FoodHealthResponse(
            isHealthy: true,
            sources: [
                "fdc": "https://api.nal.usda.gov/fdc/v1",
                "dsld": "https://api.ods.od.nih.gov/dsld/v9",
                "dsid": "https://dsid-api-dev.app.cloud.gov/v1",
                "off": "https://world.openfoodfacts.org",
            ],
        )
    }

    func searchFoods(query: String, limit: Int?) async throws -> FoodSearchResponse {
        try? await Task.sleep(nanoseconds: 200_000_000)

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return FoodSearchResponse(query: query, generic: [], branded: [])
        }

        let tokens = trimmed.lowercased().split(separator: " ")
        let filtered = Self.catalog.filter { food in
            let hay = "\(food.name) \(food.brand ?? "")".lowercased()
            return tokens.allSatisfy { hay.contains($0) }
        }

        let branded = filtered.filter { $0.brand != nil }
        let generic = filtered.filter { $0.brand == nil }

        let brandedCards = branded.prefix(limit ?? 20).map { food in
            FoodMinimalCard(
                id: "fdc:\(food.id)",
                kind: .brandedFood,
                code: food.gtinUpc,
                description: food.name,
                brand: food.brand,
                serving: FoodServing(
                    amount: food.servingSize,
                    unit: food.servingSizeUnit,
                    household: food.householdServingFullText,
                ),
                nutrients: [],
                provenance: FoodProvenance(
                    source: .fdc,
                    id: "\(food.id)",
                    fetchedAt: "2025-09-26T21:00:00Z",
                ),
            )
        }

        let genericCards = generic.prefix(limit ?? 20).map { food in
            FoodMinimalCard(
                id: "fdc:\(food.id)",
                kind: .genericFood,
                code: nil,
                description: food.name,
                brand: nil,
                serving: FoodServing(
                    amount: food.servingSize,
                    unit: food.servingSizeUnit,
                    household: food.householdServingFullText,
                ),
                nutrients: [],
                provenance: FoodProvenance(
                    source: .fdc,
                    id: "\(food.id)",
                    fetchedAt: "2025-09-26T21:00:00Z",
                ),
            )
        }

        return FoodSearchResponse(
            query: query,
            generic: Array(genericCards),
            branded: Array(brandedCards),
        )
    }

    func getFoodByBarcode(code: String) async throws -> FoodMinimalCard {
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Mock barcode lookup - return first branded food with UPC
        if let food = Self.catalog.first(where: { $0.gtinUpc == code && $0.brand != nil }) {
            return FoodMinimalCard(
                id: "gtin:\(food.gtinUpc ?? "")",
                kind: .brandedFood,
                code: food.gtinUpc,
                description: food.name,
                brand: food.brand,
                serving: FoodServing(
                    amount: food.servingSize,
                    unit: food.servingSizeUnit,
                    household: food.householdServingFullText,
                ),
                nutrients: [],
                provenance: FoodProvenance(
                    source: .fdc,
                    id: "\(food.id)",
                    fetchedAt: "2025-09-26T21:00:00Z",
                ),
            )
        }

        throw FDCError.noResults
    }

    func getFood(gid: String) async throws -> FoodMinimalCard {
        try? await Task.sleep(nanoseconds: 150_000_000)

        // Extract FDC ID from GID
        if gid.hasPrefix("fdc:"), let fdcId = Int(gid.dropFirst(4)) {
            if let food = Self.catalog.first(where: { $0.id == fdcId }) {
                return FoodMinimalCard(
                    id: gid,
                    kind: food.brand != nil ? .brandedFood : .genericFood,
                    code: food.gtinUpc,
                    description: food.name,
                    brand: food.brand,
                    serving: FoodServing(
                        amount: food.servingSize,
                        unit: food.servingSizeUnit,
                        household: food.householdServingFullText,
                    ),
                    nutrients: [],
                    provenance: FoodProvenance(
                        source: .fdc,
                        id: "\(food.id)",
                        fetchedAt: "2025-09-26T21:00:00Z",
                    ),
                )
            }
        }

        // Handle GTIN GID from barcode lookup
        if gid.hasPrefix("gtin:") {
            let gtinCode = String(gid.dropFirst(5))
            // Try to find food by exact GTIN match first
            if let food = Self.catalog.first(where: { $0.gtinUpc == gtinCode && $0.brand != nil }) {
                return FoodMinimalCard(
                    id: gid,
                    kind: .brandedFood,
                    code: food.gtinUpc,
                    description: food.name,
                    brand: food.brand,
                    serving: FoodServing(
                        amount: food.servingSize,
                        unit: food.servingSizeUnit,
                        household: food.householdServingFullText,
                    ),
                    nutrients: [],
                    provenance: FoodProvenance(
                        source: .fdc,
                        id: "\(food.id)",
                        fetchedAt: "2025-09-26T21:00:00Z",
                    ),
                )
            }

            // If no exact match, try removing leading zeros
            let originalBarcode = gtinCode.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
            if let food = Self.catalog.first(where: { $0.gtinUpc == originalBarcode && $0.brand != nil }) {
                return FoodMinimalCard(
                    id: gid,
                    kind: .brandedFood,
                    code: food.gtinUpc,
                    description: food.name,
                    brand: food.brand,
                    serving: FoodServing(
                        amount: food.servingSize,
                        unit: food.servingSizeUnit,
                        household: food.householdServingFullText,
                    ),
                    nutrients: [],
                    provenance: FoodProvenance(
                        source: .fdc,
                        id: "\(food.id)",
                        fetchedAt: "2025-09-26T21:00:00Z",
                    ),
                )
            }
        }

        throw FDCError.noResults
    }

    func getFoodDetails(gid: String) async throws -> FoodAuthoritativeDetail {
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Extract FDC ID from GID
        if gid.hasPrefix("fdc:"), let fdcId = Int(gid.dropFirst(4)) {
            if let food = Self.catalog.first(where: { $0.id == fdcId }) {
                // Create mock nutrients based on the food data
                let mockNutrients = [
                    FoodNutrient(
                        id: 1008,
                        name: "Energy",
                        unit: "kcal",
                        amount: Double(food.calories),
                        basis: .perServing,
                    ),
                    FoodNutrient(
                        id: 1003,
                        name: "Protein",
                        unit: "g",
                        amount: Double(food.protein),
                        basis: .perServing,
                    ),
                    FoodNutrient(
                        id: 1004,
                        name: "Total lipid (fat)",
                        unit: "g",
                        amount: Double(food.fat),
                        basis: .perServing,
                    ),
                    FoodNutrient(
                        id: 1005,
                        name: "Carbohydrate, by difference",
                        unit: "g",
                        amount: Double(food.carbs),
                        basis: .perServing,
                    ),
                ]

                return FoodAuthoritativeDetail(
                    id: gid,
                    kind: food.brand != nil ? .brandedFood : .genericFood,
                    code: food.gtinUpc,
                    description: food.name,
                    brand: food.brand,
                    ingredientsText: food.ingredients,
                    serving: FoodServing(
                        amount: food.servingSize ?? 100.0,
                        unit: food.servingSizeUnit ?? "g",
                        household: food.householdServingFullText ?? "1 serving",
                    ),
                    portions: [],
                    nutrients: mockNutrients,
                    dsidPredictions: nil,
                    provenance: FoodProvenance(
                        source: .fdc,
                        id: "\(food.id)",
                        fetchedAt: "2025-09-26T21:00:00Z",
                    ),
                )
            }
        }

        // Handle GTIN GID from barcode lookup
        if gid.hasPrefix("gtin:") {
            let gtinCode = String(gid.dropFirst(5))
            // Try to find food by exact GTIN match first
            if let food = Self.catalog.first(where: { $0.gtinUpc == gtinCode && $0.brand != nil }) {
                // Create mock nutrients based on the food data
                let mockNutrients = [
                    FoodNutrient(
                        id: 1008,
                        name: "Energy",
                        unit: "kcal",
                        amount: Double(food.calories),
                        basis: .perServing,
                    ),
                    FoodNutrient(
                        id: 1003,
                        name: "Protein",
                        unit: "g",
                        amount: Double(food.protein),
                        basis: .perServing,
                    ),
                    FoodNutrient(
                        id: 1004,
                        name: "Total lipid (fat)",
                        unit: "g",
                        amount: Double(food.fat),
                        basis: .perServing,
                    ),
                    FoodNutrient(
                        id: 1005,
                        name: "Carbohydrate, by difference",
                        unit: "g",
                        amount: Double(food.carbs),
                        basis: .perServing,
                    ),
                ]

                return FoodAuthoritativeDetail(
                    id: gid,
                    kind: .brandedFood,
                    code: food.gtinUpc,
                    description: food.name,
                    brand: food.brand,
                    ingredientsText: food.ingredients,
                    serving: FoodServing(
                        amount: food.servingSize ?? 100.0,
                        unit: food.servingSizeUnit ?? "g",
                        household: food.householdServingFullText ?? "1 serving",
                    ),
                    portions: [],
                    nutrients: mockNutrients,
                    dsidPredictions: nil,
                    provenance: FoodProvenance(
                        source: .fdc,
                        id: "\(food.id)",
                        fetchedAt: "2025-09-26T21:00:00Z",
                    ),
                )
            }

            // If no exact match, try removing leading zeros
            let originalBarcode = gtinCode.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
            if let food = Self.catalog.first(where: { $0.gtinUpc == originalBarcode && $0.brand != nil }) {
                // Create mock nutrients based on the food data
                let mockNutrients = [
                    FoodNutrient(
                        id: 1008,
                        name: "Energy",
                        unit: "kcal",
                        amount: Double(food.calories),
                        basis: .perServing,
                    ),
                    FoodNutrient(
                        id: 1003,
                        name: "Protein",
                        unit: "g",
                        amount: Double(food.protein),
                        basis: .perServing,
                    ),
                    FoodNutrient(
                        id: 1004,
                        name: "Total lipid (fat)",
                        unit: "g",
                        amount: Double(food.fat),
                        basis: .perServing,
                    ),
                    FoodNutrient(
                        id: 1005,
                        name: "Carbohydrate, by difference",
                        unit: "g",
                        amount: Double(food.carbs),
                        basis: .perServing,
                    ),
                ]

                return FoodAuthoritativeDetail(
                    id: gid,
                    kind: .brandedFood,
                    code: food.gtinUpc,
                    description: food.name,
                    brand: food.brand,
                    ingredientsText: food.ingredients,
                    serving: FoodServing(
                        amount: food.servingSize ?? 100.0,
                        unit: food.servingSizeUnit ?? "g",
                        household: food.householdServingFullText ?? "1 serving",
                    ),
                    portions: [],
                    nutrients: mockNutrients,
                    dsidPredictions: nil,
                    provenance: FoodProvenance(
                        source: .fdc,
                        id: "\(food.id)",
                        fetchedAt: "2025-09-26T21:00:00Z",
                    ),
                )
            }
        }

        // Provide fallback response for unknown FDC IDs
        let fallbackNutrients = [
            FoodNutrient(
                id: 1008,
                name: "Energy",
                unit: "kcal",
                amount: 100.0,
                basis: .perServing,
            ),
            FoodNutrient(
                id: 1003,
                name: "Protein",
                unit: "g",
                amount: 2.0,
                basis: .perServing,
            ),
            FoodNutrient(
                id: 1004,
                name: "Total lipid (fat)",
                unit: "g",
                amount: 1.0,
                basis: .perServing,
            ),
            FoodNutrient(
                id: 1005,
                name: "Carbohydrate, by difference",
                unit: "g",
                amount: 22.0,
                basis: .perServing,
            ),
        ]

        return FoodAuthoritativeDetail(
            id: gid,
            kind: .genericFood,
            code: nil,
            description: "Brown Rice, cooked",
            brand: nil,
            ingredientsText: "Brown rice",
            serving: FoodServing(
                amount: 100.0,
                unit: "g",
                household: "1 serving",
            ),
            portions: [],
            nutrients: fallbackNutrients,
            dsidPredictions: nil,
            provenance: FoodProvenance(
                source: .fdc,
                id: "999999",
                fetchedAt: "2025-09-26T21:00:00Z",
            ),
        )
    }

    // Canonical mock catalog (details first; summaries derived from this)
    private static let catalog: [FDCFoodDetails] = [
        .init(
            id: 1234,
            name: "Greek Yogurt, Plain",
            brand: "Fage",
            calories: 100,
            protein: 17,
            fat: 0,
            carbs: 6,
            dataType: "Branded",
            brandOwner: "Fage",
            brandName: "Fage",
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: nil,
            labelNutrients: nil,
            foodNutrients: nil,
        ),
        .init(
            id: 5678,
            name: "Peanut Butter",
            brand: "Jif",
            calories: 190,
            protein: 7,
            fat: 16,
            carbs: 8,
            dataType: "Branded",
            brandOwner: "Jif",
            brandName: "Jif",
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: nil,
            labelNutrients: nil,
            foodNutrients: nil,
        ),
        .init(
            id: 9012,
            name: "Brown Rice, cooked",
            brand: nil,
            calories: 216,
            protein: 5,
            fat: 2,
            carbs: 45,
            dataType: "Foundation",
            brandOwner: nil,
            brandName: nil,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: nil,
            labelNutrients: nil,
            foodNutrients: nil,
        ),
        // extras for nicer search feel
        .init(
            id: 1001,
            name: "Banana, raw",
            brand: nil,
            calories: 90,
            protein: 1,
            fat: 0,
            carbs: 23,
            dataType: "Foundation",
            brandOwner: nil,
            brandName: nil,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: nil,
            labelNutrients: nil,
            foodNutrients: nil,
        ),
        .init(
            id: 1002,
            name: "Chicken Breast, cooked",
            brand: nil,
            calories: 165,
            protein: 31,
            fat: 3,
            carbs: 0,
            dataType: "Foundation",
            brandOwner: nil,
            brandName: nil,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: nil,
            labelNutrients: nil,
            foodNutrients: nil,
        ),
        .init(
            id: 1003,
            name: "Oatmeal, rolled oats",
            brand: nil,
            calories: 150,
            protein: 5,
            fat: 3,
            carbs: 27,
            dataType: "Foundation",
            brandOwner: nil,
            brandName: nil,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: nil,
            labelNutrients: nil,
            foodNutrients: nil,
        ),
        .init(
            id: 1004,
            name: "Greek Yogurt, Strawberry",
            brand: "Chobani",
            calories: 140,
            protein: 12,
            fat: 2,
            carbs: 16,
            dataType: "Branded",
            brandOwner: "Chobani",
            brandName: "Chobani",
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: "031604031121",
            labelNutrients: nil,
            foodNutrients: nil,
        ),
        .init(
            id: 1005,
            name: "Coca-Cola Classic",
            brand: "Coca-Cola",
            calories: 140,
            protein: 0,
            fat: 0,
            carbs: 39,
            dataType: "Branded",
            brandOwner: "Coca-Cola Company",
            brandName: "Coca-Cola",
            servingSize: 355.0,
            servingSizeUnit: "ml",
            householdServingFullText: "1 can",
            packageWeight: "355ml",
            foodCategory: "Beverages",
            foodCategoryId: 9,
            ingredients: "Carbonated water, high fructose corn syrup, caramel color, phosphoric acid, natural flavors, caffeine",
            marketCountry: "US",
            tradeChannels: ["Grocery"],
            publishedDate: "2023-01-01",
            modifiedDate: "2023-01-01",
            gtinUpc: "049000028911",
            labelNutrients: nil,
            foodNutrients: nil,
        ),
        .init(
            id: 1006,
            name: "Lay's Classic Potato Chips",
            brand: "Lay's",
            calories: 160,
            protein: 2,
            fat: 10,
            carbs: 15,
            dataType: "Branded",
            brandOwner: "Frito-Lay",
            brandName: "Lay's",
            servingSize: 28.0,
            servingSizeUnit: "g",
            householdServingFullText: "1 oz",
            packageWeight: "28g",
            foodCategory: "Snacks",
            foodCategoryId: 10,
            ingredients: "Potatoes, vegetable oil, salt",
            marketCountry: "US",
            tradeChannels: ["Grocery", "Convenience"],
            publishedDate: "2023-01-01",
            modifiedDate: "2023-01-01",
            gtinUpc: "028400000000",
            labelNutrients: nil,
            foodNutrients: nil,
        ),
    ]

    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        let result = try await searchFoodsWithPagination(matching: query, page: page, pageSize: 25)
        return result.foods
    }

    func searchFoodsWithPagination(matching query: String, page: Int, pageSize: Int) async throws -> FDCSearchResult {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return FDCSearchResult(foods: [], totalHits: 0, currentPage: page, totalPages: 0, pageSize: pageSize)
        }

        try? await Task.sleep(nanoseconds: 150_000_000) // small latency

        let tokens = trimmed.lowercased().split(separator: " ")
        let filtered = Self.catalog.filter { food in
            let hay = "\(food.name) \(food.brand ?? "")".lowercased()
            return tokens.allSatisfy { hay.contains($0) }
        }

        // Calculate pagination
        let totalHits = filtered.count
        let totalPages = max(1, (totalHits + pageSize - 1) / pageSize)
        let start = max(0, (page - 1) * pageSize)
        let end = min(filtered.count, start + pageSize)
        let slice = (start < end) ? filtered[start ..< end] : []

        let foods = slice.map {
            FDCFoodSummary(
                id: $0.id,
                name: $0.name,
                brand: $0.brand,
                serving: nil,
                upc: nil,
                publishedDate: nil,
                modifiedDate: nil,
                dataType: "Branded",
                brandOwner: $0.brand,
                brandName: $0.brand,
                servingSize: nil,
                servingSizeUnit: nil,
                householdServingFullText: nil,
                packageWeight: nil,
                foodCategory: nil,
                foodCategoryId: nil,
                ingredients: nil,
                marketCountry: nil,
                tradeChannels: nil,
                calories: Double($0.calories),
                protein: Double($0.protein),
                fat: Double($0.fat),
                saturatedFat: nil,
                transFat: nil,
                cholesterol: nil,
                sodium: nil,
                carbohydrates: Double($0.carbs),
                fiber: nil,
                sugars: nil,
                calcium: nil,
                iron: nil,
                potassium: nil,
                macroSummary: MacroSummary(
                    calories: Double($0.calories),
                    protein: Double($0.protein),
                    fat: Double($0.fat),
                    carbohydrates: Double($0.carbs),
                    fiber: nil,
                    sugars: nil,
                ),
            )
        }

        return FDCSearchResult(
            foods: foods,
            totalHits: totalHits,
            currentPage: page,
            totalPages: totalPages,
            pageSize: pageSize,
        )
    }

    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        try? await Task.sleep(nanoseconds: 120_000_000)
        if let hit = Self.catalog.first(where: { $0.id == fdcId }) {
            return hit
        }
        // safe fallback
        return .init(
            id: fdcId,
            name: "Brown Rice, cooked",
            brand: nil,
            calories: 216,
            protein: 5,
            fat: 2,
            carbs: 45,
            dataType: "Foundation",
            brandOwner: nil,
            brandName: nil,
            servingSize: nil,
            servingSizeUnit: nil,
            householdServingFullText: nil,
            packageWeight: nil,
            foodCategory: nil,
            foodCategoryId: nil,
            ingredients: nil,
            marketCountry: nil,
            tradeChannels: nil,
            publishedDate: nil,
            modifiedDate: nil,
            gtinUpc: nil,
            labelNutrients: nil,
            foodNutrients: nil,
        )
    }

    func fetchFoodDetailResponse(fdcId: Int) async throws -> ProxyFoodDetailResponse {
        try? await Task.sleep(nanoseconds: 120_000_000)

        // Create a mock ProxyFoodDetailResponse with realistic data
        let mockNutrients = [
            ProxyFoodNutrient(
                nutrient: ProxyNutrient(id: 1008, number: "208", name: "Energy", rank: 300, unitName: "kcal"),
                amount: 100.0,
                type: "FoodNutrient",
                foodNutrientDerivation: ProxyFoodNutrientDerivation(
                    id: 1,
                    code: "LCCD",
                    description: "Calculated from a daily value percentage per serving size measure",
                    foodNutrientSource: ProxyFoodNutrientSource(
                        id: 1,
                        code: "LCCD",
                        description: "Calculated from a daily value percentage per serving size measure",
                    ),
                ),
                id: 1,
                dataPoints: 1,
                max: nil,
                min: nil,
                median: nil,
                minYearAcquired: nil,
                nutrientAnalysisDetails: nil,
            ),
            ProxyFoodNutrient(
                nutrient: ProxyNutrient(id: 1003, number: "203", name: "Protein", rank: 600, unitName: "g"),
                amount: 7.0,
                type: "FoodNutrient",
                foodNutrientDerivation: nil,
                id: 2,
                dataPoints: 1,
                max: nil,
                min: nil,
                median: nil,
                minYearAcquired: nil,
                nutrientAnalysisDetails: nil,
            ),
        ]

        if let hit = Self.catalog.first(where: { $0.id == fdcId }) {
            // Create label nutrients for testing fallback functionality
            let labelNutrients = ProxyLabelNutrients(
                fat: ProxyLabelNutrient(value: Double(hit.fat)),
                saturatedFat: nil,
                transFat: nil,
                cholesterol: nil,
                sodium: nil,
                carbohydrates: ProxyLabelNutrient(value: Double(hit.carbs)),
                fiber: nil,
                sugars: nil,
                protein: ProxyLabelNutrient(value: Double(hit.protein)),
                calcium: nil,
                iron: nil,
                calories: ProxyLabelNutrient(value: Double(hit.calories)),
            )

            return ProxyFoodDetailResponse(
                fdcId: hit.id,
                description: hit.name,
                publicationDate: "2023-01-01",
                foodNutrients: mockNutrients,
                dataType: "Branded",
                foodClass: "Processed",
                inputFoods: nil,
                foodComponents: nil,
                foodAttributes: nil,
                nutrientConversionFactors: nil,
                ndbNumber: hit.id,
                isHistoricalReference: false,
                foodCategory: ProxyFoodCategory(id: 1, code: "0100", description: "Dairy and Egg Products"),
                brandOwner: hit.brand,
                brandName: hit.brand,
                dataSource: "Mock",
                gtinUpc: nil,
                marketCountry: "United States",
                servingSize: 100.0,
                servingSizeUnit: "g",
                householdServingFullText: "1 cup",
                ingredients: "Brown rice",
                brandedFoodCategory: "Grains",
                packageWeight: nil,
                discontinuedDate: nil,
                availableDate: "2023-01-01",
                modifiedDate: "2023-01-01",
                foodPortions: nil,
                foodUpdateLog: nil,
                labelNutrients: labelNutrients,
                scientificName: nil,
                footNote: nil,
                foodCode: nil,
                endDate: nil,
                startDate: nil,
                wweiaFoodCategory: nil,
                foodMeasures: nil,
                microbes: nil,
                tradeChannels: nil,
                allHighlightFields: nil,
                score: nil,
                foodVersionIds: nil,
                foodAttributeTypes: nil,
                finalFoodInputFoods: nil,
            )
        }

        // safe fallback
        return ProxyFoodDetailResponse(
            fdcId: fdcId,
            description: "Brown Rice, cooked",
            publicationDate: "2023-01-01",
            foodNutrients: mockNutrients,
            dataType: "Foundation",
            foodClass: "Raw",
            inputFoods: nil,
            foodComponents: nil,
            foodAttributes: nil,
            nutrientConversionFactors: nil,
            ndbNumber: fdcId,
            isHistoricalReference: false,
            foodCategory: ProxyFoodCategory(id: 2, code: "2000", description: "Cereal Grains and Pasta"),
            brandOwner: nil,
            brandName: nil,
            dataSource: "Mock",
            gtinUpc: nil,
            marketCountry: "United States",
            servingSize: 100.0,
            servingSizeUnit: "g",
            householdServingFullText: "1 cup",
            ingredients: "Brown rice",
            brandedFoodCategory: "Grains",
            packageWeight: nil,
            discontinuedDate: nil,
            availableDate: "2023-01-01",
            modifiedDate: "2023-01-01",
            foodPortions: nil,
            foodUpdateLog: nil,
            labelNutrients: nil,
            scientificName: nil,
            footNote: nil,
            foodCode: nil,
            endDate: nil,
            startDate: nil,
            wweiaFoodCategory: nil,
            foodMeasures: nil,
            microbes: nil,
            tradeChannels: nil,
            allHighlightFields: nil,
            score: nil,
            foodVersionIds: nil,
            foodAttributeTypes: nil,
            finalFoodInputFoods: nil,
        )
    }
}
