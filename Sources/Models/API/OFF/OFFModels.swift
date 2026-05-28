//
//  OFFModels.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Open Food Facts Models

public struct OffReadResponse: Codable, Sendable {
    public let status: Int? // 1=found, 0=not found
    public let code: String?
    public let product: OffProduct?
}

public struct OffProduct: Codable, Sendable {
    // Identity
    public let code: String? // barcode
    public let productName: String?
    public let brands: String?
    public let quantity: String? // free text, e.g. "3 x 150 g"
    public let packaging: String?
    public let categories: String?
    public let categoriesTags: [String]?
    public let countries: String?
    public let countriesTags: [String]?

    // Ingredients & allergens
    public let ingredientsText: String?
    public let ingredients: [OffIngredient]?
    public let allergens: String?
    public let allergensTags: [String]?
    public let additivesTags: [String]?

    // Images
    public let imageURL: URL?
    public let imageSmallURL: URL?
    public let selectedImages: OffSelectedImages?

    // Nutrition
    public let nutriments: OffNutriments?
    public let nutritionDataPer: String? // "100g" | "serving"
    public let servingSize: String? // free text; may include grams
    public let servingQuantity: Double? // parsed grams/ml when OFF can infer

    // Scores (optional)
    public let nutriscoreGrade: String?
    public let novaGroup: Int?
    public let ecoscoreGrade: String?

    // Raw catch-alls you may care about later
    public let lang: String?
    public let languageCode: String? // default language code
    public let lastModifiedT: Int? // unix timestamp

    // Memberwise initializer
    public init(
        code: String? = nil,
        productName: String? = nil,
        brands: String? = nil,
        quantity: String? = nil,
        packaging: String? = nil,
        categories: String? = nil,
        categoriesTags: [String]? = nil,
        countries: String? = nil,
        countriesTags: [String]? = nil,
        ingredientsText: String? = nil,
        ingredients: [OffIngredient]? = nil,
        allergens: String? = nil,
        allergensTags: [String]? = nil,
        additivesTags: [String]? = nil,
        imageURL: URL? = nil,
        imageSmallURL: URL? = nil,
        selectedImages: OffSelectedImages? = nil,
        nutriments: OffNutriments? = nil,
        nutritionDataPer: String? = nil,
        servingSize: String? = nil,
        servingQuantity: Double? = nil,
        nutriscoreGrade: String? = nil,
        novaGroup: Int? = nil,
        ecoscoreGrade: String? = nil,
        lang: String? = nil,
        languageCode: String? = nil,
        lastModifiedT: Int? = nil
    ) {
        self.code = code
        self.productName = productName
        self.brands = brands
        self.quantity = quantity
        self.packaging = packaging
        self.categories = categories
        self.categoriesTags = categoriesTags
        self.countries = countries
        self.countriesTags = countriesTags
        self.ingredientsText = ingredientsText
        self.ingredients = ingredients
        self.allergens = allergens
        self.allergensTags = allergensTags
        self.additivesTags = additivesTags
        self.imageURL = imageURL
        self.imageSmallURL = imageSmallURL
        self.selectedImages = selectedImages
        self.nutriments = nutriments
        self.nutritionDataPer = nutritionDataPer
        self.servingSize = servingSize
        self.servingQuantity = servingQuantity
        self.nutriscoreGrade = nutriscoreGrade
        self.novaGroup = novaGroup
        self.ecoscoreGrade = ecoscoreGrade
        self.lang = lang
        self.languageCode = languageCode
        self.lastModifiedT = lastModifiedT
    }

    // Custom decoder to handle type mismatches
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Identity
        code = try container.decodeIfPresent(String.self, forKey: .code)
        productName = try container.decodeIfPresent(String.self, forKey: .productName)
        brands = try container.decodeIfPresent(String.self, forKey: .brands)
        quantity = try container.decodeIfPresent(String.self, forKey: .quantity)
        packaging = try container.decodeIfPresent(String.self, forKey: .packaging)
        categories = try container.decodeIfPresent(String.self, forKey: .categories)
        categoriesTags = try container.decodeIfPresent([String].self, forKey: .categoriesTags)
        countries = try container.decodeIfPresent(String.self, forKey: .countries)
        countriesTags = try container.decodeIfPresent([String].self, forKey: .countriesTags)

        // Ingredients & allergens
        ingredientsText = try container.decodeIfPresent(String.self, forKey: .ingredientsText)
        ingredients = try container.decodeIfPresent([OffIngredient].self, forKey: .ingredients)
        allergens = try container.decodeIfPresent(String.self, forKey: .allergens)
        allergensTags = try container.decodeIfPresent([String].self, forKey: .allergensTags)
        additivesTags = try container.decodeIfPresent([String].self, forKey: .additivesTags)

        // Images
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        imageSmallURL = try container.decodeIfPresent(URL.self, forKey: .imageSmallURL)
        selectedImages = try container.decodeIfPresent(OffSelectedImages.self, forKey: .selectedImages)

        // Nutrition
        nutriments = try container.decodeIfPresent(OffNutriments.self, forKey: .nutriments)
        nutritionDataPer = try container.decodeIfPresent(String.self, forKey: .nutritionDataPer)
        servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)

        // Handle servingQuantity as either String or Double
        if let servingQuantityString = try? container.decodeIfPresent(String.self, forKey: .servingQuantity) {
            servingQuantity = Double(servingQuantityString)
        } else {
            servingQuantity = try container.decodeIfPresent(Double.self, forKey: .servingQuantity)
        }

        // Scores
        nutriscoreGrade = try container.decodeIfPresent(String.self, forKey: .nutriscoreGrade)
        novaGroup = try container.decodeIfPresent(Int.self, forKey: .novaGroup)
        ecoscoreGrade = try container.decodeIfPresent(String.self, forKey: .ecoscoreGrade)

        // Raw catch-alls
        lang = try container.decodeIfPresent(String.self, forKey: .lang)
        languageCode = try container.decodeIfPresent(String.self, forKey: .languageCode)
        lastModifiedT = try container.decodeIfPresent(Int.self, forKey: .lastModifiedT)
    }

    // Custom encoder to match the decoder
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(code, forKey: .code)
        try container.encodeIfPresent(productName, forKey: .productName)
        try container.encodeIfPresent(brands, forKey: .brands)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(packaging, forKey: .packaging)
        try container.encodeIfPresent(categories, forKey: .categories)
        try container.encodeIfPresent(categoriesTags, forKey: .categoriesTags)
        try container.encodeIfPresent(countries, forKey: .countries)
        try container.encodeIfPresent(countriesTags, forKey: .countriesTags)

        try container.encodeIfPresent(ingredientsText, forKey: .ingredientsText)
        try container.encodeIfPresent(ingredients, forKey: .ingredients)
        try container.encodeIfPresent(allergens, forKey: .allergens)
        try container.encodeIfPresent(allergensTags, forKey: .allergensTags)
        try container.encodeIfPresent(additivesTags, forKey: .additivesTags)

        try container.encodeIfPresent(imageURL, forKey: .imageURL)
        try container.encodeIfPresent(imageSmallURL, forKey: .imageSmallURL)
        try container.encodeIfPresent(selectedImages, forKey: .selectedImages)

        try container.encodeIfPresent(nutriments, forKey: .nutriments)
        try container.encodeIfPresent(nutritionDataPer, forKey: .nutritionDataPer)
        try container.encodeIfPresent(servingSize, forKey: .servingSize)
        try container.encodeIfPresent(servingQuantity, forKey: .servingQuantity)

        try container.encodeIfPresent(nutriscoreGrade, forKey: .nutriscoreGrade)
        try container.encodeIfPresent(novaGroup, forKey: .novaGroup)
        try container.encodeIfPresent(ecoscoreGrade, forKey: .ecoscoreGrade)

        try container.encodeIfPresent(lang, forKey: .lang)
        try container.encodeIfPresent(languageCode, forKey: .languageCode)
        try container.encodeIfPresent(lastModifiedT, forKey: .lastModifiedT)
    }

    // CodingKeys map OFF's fields → Swift names
    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case quantity
        case packaging
        case categories
        case categoriesTags = "categories_tags"
        case countries
        case countriesTags = "countries_tags"
        case ingredientsText = "ingredients_text"
        case ingredients
        case allergens
        case allergensTags = "allergens_tags"
        case additivesTags = "additives_tags"
        case imageURL = "image_url"
        case imageSmallURL = "image_small_url"
        case selectedImages = "selected_images"
        case nutriments
        case nutritionDataPer = "nutrition_data_per"
        case servingSize = "serving_size"
        case servingQuantity = "serving_quantity"
        case nutriscoreGrade = "nutriscore_grade"
        case novaGroup = "nova_group"
        case ecoscoreGrade = "ecoscore_grade"
        case lang
        case languageCode = "language_code"
        case lastModifiedT = "last_modified_t"
    }
}

public struct OffIngredient: Codable {
    public let id: String?
    public let text: String?
    public let rank: Int?
    public let percent: Double?
    public let vegan: String?
    public let vegetarian: String?
}

// OFF selected_images → sets of URLs (by language code)
public struct OffSelectedImages: Codable {
    public let front: OffImageSet?
    public let ingredients: OffImageSet?
    public let nutrition: OffImageSet?
}

public struct OffImageSet: Codable {
    public let display: [String: URL]?
    public let small: [String: URL]?
    public let thumb: [String: URL]?
}

// OFF nutriments (typed superset; all optional)
// Includes _100g and _serving variants; some "prepared" variants for reconstituted foods.
public struct OffNutriments: Codable {
    // Energy
    public let energyKcal100g: Double?
    public let energyKj100g: Double?
    public let energy100g: Double? // sometimes only "energy" (usually kJ)
    public let energyKcalServing: Double?
    public let energyKjServing: Double?
    public let energyServing: Double?

    // Macros
    public let fat100g: Double?
    public let saturatedFat100g: Double?
    public let transFat100g: Double?
    public let carbs100g: Double?
    public let sugars100g: Double?
    public let fiber100g: Double?
    public let proteins100g: Double?

    public let fatServing: Double?
    public let saturatedFatServing: Double?
    public let transFatServing: Double?
    public let carbohydratesServing: Double?
    public let sugarsServing: Double?
    public let fiberServing: Double?
    public let proteinsServing: Double?

    // Sodium/Salt (units can be "g" on OFF; check *_unit fields below)
    public let sodium100g: Double?
    public let sodiumServing: Double?
    public let salt100g: Double?
    public let saltServing: Double?

    // Common micros (sample; OFF has many more)
    public let calcium100g: Double?
    public let iron100g: Double?
    public let potassium100g: Double?
    public let magnesium100g: Double?
    public let zinc100g: Double?
    public let vitaminA100g: Double?
    public let vitaminC100g: Double?
    public let vitaminD100g: Double?
    public let vitaminE100g: Double?
    public let vitaminB12100g: Double?
    public let folate100g: Double?

    // Units (when provided)
    public let sodiumUnit: String?
    public let saltUnit: String?
    public let energyUnit: String?
    public let fatUnit: String?
    public let carbohydratesUnit: String?
    public let sugarsUnit: String?
    public let fiberUnit: String?
    public let proteinsUnit: String?

    // Prepared variants (if OFF has "_prepared_*")
    public let energyKcalPrepared100g: Double?
    public let energyKcalPreparedServing: Double?
    public let fatPrepared100g: Double?
    public let fatPreparedServing: Double?
    public let carbohydratesPrepared100g: Double?
    public let carbohydratesPreparedServing: Double?
    public let proteinsPrepared100g: Double?
    public let proteinsPreparedServing: Double?

    enum CodingKeys: String, CodingKey {
        // Energy
        case energyKcal100g = "energy-kcal_100g"
        case energyKj100g = "energy-kj_100g"
        case energy100g = "energy_100g"
        case energyKcalServing = "energy-kcal_serving"
        case energyKjServing = "energy-kj_serving"
        case energyServing = "energy_serving"

        // Macros _100g
        case fat100g = "fat_100g"
        case saturatedFat100g = "saturated-fat_100g"
        case transFat100g = "trans-fat_100g"
        case carbs100g = "carbohydrates_100g"
        case sugars100g = "sugars_100g"
        case fiber100g = "fiber_100g"
        case proteins100g = "proteins_100g"

        // Macros _serving
        case fatServing = "fat_serving"
        case saturatedFatServing = "saturated-fat_serving"
        case transFatServing = "trans-fat_serving"
        case carbohydratesServing = "carbohydrates_serving"
        case sugarsServing = "sugars_serving"
        case fiberServing = "fiber_serving"
        case proteinsServing = "proteins_serving"

        // Sodium/Salt
        case sodium100g = "sodium_100g"
        case sodiumServing = "sodium_serving"
        case salt100g = "salt_100g"
        case saltServing = "salt_serving"

        // Micros (sample)
        case calcium100g = "calcium_100g"
        case iron100g = "iron_100g"
        case potassium100g = "potassium_100g"
        case magnesium100g = "magnesium_100g"
        case zinc100g = "zinc_100g"
        case vitaminA100g = "vitamin-a_100g"
        case vitaminC100g = "vitamin-c_100g"
        case vitaminD100g = "vitamin-d_100g"
        case vitaminE100g = "vitamin-e_100g"
        case vitaminB12100g = "vitamin-b12_100g"
        case folate100g = "folate_100g"

        // Units
        case sodiumUnit = "sodium_unit"
        case saltUnit = "salt_unit"
        case energyUnit = "energy_unit"
        case fatUnit = "fat_unit"
        case carbohydratesUnit = "carbohydrates_unit"
        case sugarsUnit = "sugars_unit"
        case fiberUnit = "fiber_unit"
        case proteinsUnit = "proteins_unit"

        // Prepared variants
        case energyKcalPrepared100g = "energy-kcal_prepared_100g"
        case energyKcalPreparedServing = "energy-kcal_prepared_serving"
        case fatPrepared100g = "fat_prepared_100g"
        case fatPreparedServing = "fat_prepared_serving"
        case carbohydratesPrepared100g = "carbohydrates_prepared_100g"
        case carbohydratesPreparedServing = "carbohydrates_prepared_serving"
        case proteinsPrepared100g = "proteins_prepared_100g"
        case proteinsPreparedServing = "proteins_prepared_serving"
    }
}
