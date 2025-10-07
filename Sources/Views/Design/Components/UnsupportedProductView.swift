//
//  UnsupportedProductView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
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
                headerSection()
                qaSection()
                actionButtonsSection()
            }
        }
        .safeAreaInset(edge: .bottom) {
            // Ensure content doesn't get hidden behind home indicator
            Color.clear.frame(height: 0)
        }
    }

    @ViewBuilder
    private func headerSection() -> some View {
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
    }

    @ViewBuilder
    private func qaSection() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            QARow(
                question: "Why can't I see detailed nutrition information?",
                answer: "This product is not from our supported databases (FDC). We only provide detailed nutrition information for products from this official source."
            )

            QARow(
                question: "What databases do we support?",
                answer: "• FDC (FoodData Central) - USDA's comprehensive food database"
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
    }

    @ViewBuilder
    private func actionButtonsSection() -> some View {
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
