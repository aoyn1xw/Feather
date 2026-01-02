//
//  ExperimentalSourcesView.swift
//  Feather
//
//  Experimental UI redesigned Sources (Home) view
//

import SwiftUI
import NimbleViews

struct ExperimentalSourcesView: View {
    @State private var searchText = ""
    @State private var showAddSource = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ExperimentalUITheme.Spacing.lg) {
                    // Hero Header
                    ExperimentalHeroHeader(
                        title: "Sources",
                        subtitle: "Discover amazing apps",
                        icon: "house.fill"
                    )
                    
                    // Search Bar
                    ExperimentalSearchBar(text: $searchText, placeholder: "Search sources...")
                        .padding(.horizontal, ExperimentalUITheme.Spacing.md)
                    
                    // Featured Section
                    ExperimentalFeaturedSection()
                    
                    // Sources Grid
                    ExperimentalSourcesGrid()
                }
                .padding(.bottom, 100) // Space for floating tab bar
            }
            .navigationBarHidden(true)
        }
        .accentColor(ExperimentalUITheme.Colors.accentPrimary)
    }
}

// MARK: - Hero Header
struct ExperimentalHeroHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: ExperimentalUITheme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.xs) {
                    Text(title)
                        .font(ExperimentalUITheme.Typography.largeTitle)
                        .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(ExperimentalUITheme.Typography.subheadline)
                        .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(ExperimentalUITheme.Gradients.primary)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            .padding(.top, ExperimentalUITheme.Spacing.xl)
        }
    }
}

// MARK: - Search Bar
struct ExperimentalSearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: ExperimentalUITheme.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                .font(.system(size: 16, weight: .semibold))
            
            TextField(placeholder, text: $text)
                .font(ExperimentalUITheme.Typography.body)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
                }
            }
        }
        .padding(ExperimentalUITheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                .fill(ExperimentalUITheme.Colors.backgroundSecondary)
        )
    }
}

// MARK: - Featured Section
struct ExperimentalFeaturedSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.md) {
            Text("Featured")
                .font(ExperimentalUITheme.Typography.title3)
                .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ExperimentalUITheme.Spacing.md) {
                    ForEach(0..<3) { index in
                        ExperimentalFeaturedCard(index: index)
                    }
                }
                .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            }
        }
    }
}

// MARK: - Featured Card
struct ExperimentalFeaturedCard: View {
    let index: Int
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.lg)
                .fill(ExperimentalUITheme.Gradients.primary)
                .frame(width: 300, height: 180)
            
            VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.xs) {
                Text("Featured Source \(index + 1)")
                    .font(ExperimentalUITheme.Typography.headline)
                    .foregroundStyle(.white)
                
                Text("Discover amazing apps and more")
                    .font(ExperimentalUITheme.Typography.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(ExperimentalUITheme.Spacing.md)
        }
        .shadow(
            color: ExperimentalUITheme.Shadow.md.color,
            radius: ExperimentalUITheme.Shadow.md.radius,
            x: ExperimentalUITheme.Shadow.md.x,
            y: ExperimentalUITheme.Shadow.md.y
        )
    }
}

// MARK: - Sources Grid
struct ExperimentalSourcesGrid: View {
    let columns = [
        GridItem(.flexible(), spacing: ExperimentalUITheme.Spacing.md),
        GridItem(.flexible(), spacing: ExperimentalUITheme.Spacing.md)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.md) {
            Text("All Sources")
                .font(ExperimentalUITheme.Typography.title3)
                .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            
            LazyVGrid(columns: columns, spacing: ExperimentalUITheme.Spacing.md) {
                ForEach(0..<6) { index in
                    ExperimentalSourceCard(index: index)
                }
            }
            .padding(.horizontal, ExperimentalUITheme.Spacing.md)
        }
    }
}

// MARK: - Source Card
struct ExperimentalSourceCard: View {
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.sm) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                .fill(ExperimentalUITheme.Gradients.accent)
                .frame(height: 100)
                .overlay(
                    Image(systemName: "app.badge.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Source \(index + 1)")
                    .font(ExperimentalUITheme.Typography.headline)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                
                Text("\(10 + index) apps")
                    .font(ExperimentalUITheme.Typography.caption)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
            }
            .padding(.horizontal, ExperimentalUITheme.Spacing.xs)
        }
        .experimentalCard(padding: ExperimentalUITheme.Spacing.sm)
    }
}
