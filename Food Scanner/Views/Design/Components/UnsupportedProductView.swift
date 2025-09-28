//
//  UnsupportedProductView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/26/25.
//  Q&A view explaining why a product is not available
//

import SwiftUI

struct UnsupportedProductView: View {
    let gid: String
    let source: SourceTag?
    var onSearchSimilar: (() -> Void)?
    var onTryDifferentBarcode: (() -> Void)?

    init(
        gid: String,
        source: SourceTag?,
        onSearchSimilar: (() -> Void)? = nil,
        onTryDifferentBarcode: (() -> Void)? = nil
    ) {
        self.gid = gid
        self.source = source
        self.onSearchSimilar = onSearchSimilar
        self.onTryDifferentBarcode = onTryDifferentBarcode
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(.orange)

                    Text("Product Not Available")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)

                // Q&A Section
                VStack(alignment: .leading, spacing: 20) {
                    QARow(
                        question: "Why can't I see detailed nutrition information?",
                        answer: "This product is not from our supported databases (FDC or DSLD). We only provide detailed nutrition information for products from these official sources."
                    )

                    QARow(
                        question: "What databases do we support?",
                        answer: "• FDC (FoodData Central) - USDA's comprehensive food database\n• DSLD (Dietary Supplement Label Database) - NIH's supplement database"
                    )

                    QARow(
                        question: "What can I do instead?",
                        answer: "• Search for a similar product by name\n• Look for the product in our supported databases\n• Add the product manually with basic information"
                    )

                    if let source {
                        QARow(
                            question: "Product source detected:",
                            answer: "\(source.rawValue.uppercased()) - This source is not supported for detailed nutrition information."
                        )
                    }
                }
                .padding(.horizontal)

                // Action Buttons
                VStack(spacing: 12) {
                    if let onSearchSimilar {
                        Button("Search for Similar Product") {
                            onSearchSimilar()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }

                    if let onTryDifferentBarcode {
                        Button("Try Different Barcode") {
                            onTryDifferentBarcode()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Ensure content doesn't get hidden behind home indicator
            Color.clear.frame(height: 0)
        }
    }
}

struct QARow: View {
    let question: String
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.headline)
                .foregroundColor(.primary)

            Text(answer)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("Unsupported Product View") {
    NavigationView {
        UnsupportedProductView(
            gid: "off:123456",
            source: .off
        )
        .navigationTitle("Product Details")
    }
}
