//
//  FDCModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//  Refactored: Models split into domain-specific files for better organization
//

import Foundation

// MARK: - Re-export all models for backward compatibility

// This file now serves as a central import point for all FDC-related models

// All models are now defined in separate files:
// - FDCPublicModels.swift: Public API models
// - FDCProxyModels.swift: Proxy API response models
// - FDCFoodDetailModels.swift: Detailed food response models
// - FDCNutrientModels.swift: Nutrient-related models
// - FDCUtilityModels.swift: Utility models like AnyCodable
// - FDCLegacyModels.swift: Legacy models for backward compatibility
// - FDCConversionExtensions.swift: Conversion extensions between model types
