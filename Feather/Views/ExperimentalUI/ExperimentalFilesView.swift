//
//  ExperimentalFilesView.swift
//  Feather
//
//  Experimental UI redesigned Files view
//

import SwiftUI

struct ExperimentalFilesView: View {
    @State private var selectedFolder: FileFolder = .all
    
    enum FileFolder: String, CaseIterable {
        case all = "All Files"
        case archives = "Archives"
        case signed = "Signed"
        case unsigned = "Unsigned"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ExperimentalUITheme.Spacing.lg) {
                    // Hero Header
                    ExperimentalHeroHeader(
                        title: "Files",
                        subtitle: "Manage your files",
                        icon: "folder.fill"
                    )
                    
                    // Quick Stats
                    ExperimentalQuickStats()
                    
                    // Folder Sections
                    ForEach(FileFolder.allCases, id: \.self) { folder in
                        ExperimentalFolderSection(folder: folder)
                    }
                }
                .padding(.bottom, 100)
            }
            .navigationBarHidden(true)
        }
        .accentColor(ExperimentalUITheme.Colors.accentPrimary)
    }
}

// MARK: - Quick Stats
struct ExperimentalQuickStats: View {
    var body: some View {
        HStack(spacing: ExperimentalUITheme.Spacing.md) {
            ExperimentalStatCard(
                icon: "doc.fill",
                value: "42",
                label: "Total Files"
            )
            
            ExperimentalStatCard(
                icon: "archivebox.fill",
                value: "128 MB",
                label: "Storage Used"
            )
        }
        .padding(.horizontal, ExperimentalUITheme.Spacing.md)
    }
}

// MARK: - Stat Card
struct ExperimentalStatCard: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: ExperimentalUITheme.Spacing.sm) {
            HStack(spacing: ExperimentalUITheme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
                
                Text(value)
                    .font(ExperimentalUITheme.Typography.title2)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                    .fontWeight(.bold)
            }
            
            Text(label)
                .font(ExperimentalUITheme.Typography.caption)
                .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(ExperimentalUITheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.lg)
                .fill(ExperimentalUITheme.Colors.cardBackground)
                .shadow(
                    color: ExperimentalUITheme.Shadow.sm.color,
                    radius: ExperimentalUITheme.Shadow.sm.radius,
                    x: ExperimentalUITheme.Shadow.sm.x,
                    y: ExperimentalUITheme.Shadow.sm.y
                )
        )
    }
}

// MARK: - Folder Section
struct ExperimentalFolderSection: View {
    let folder: ExperimentalFilesView.FileFolder
    
    var body: some View {
        VStack(alignment: .leading, spacing: ExperimentalUITheme.Spacing.md) {
            HStack {
                Text(folder.rawValue)
                    .font(ExperimentalUITheme.Typography.title3)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int.random(in: 3...12)) items")
                    .font(ExperimentalUITheme.Typography.caption)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
            }
            .padding(.horizontal, ExperimentalUITheme.Spacing.md)
            
            VStack(spacing: ExperimentalUITheme.Spacing.sm) {
                ForEach(0..<3) { index in
                    ExperimentalFileRow(index: index, folder: folder)
                }
            }
            .padding(.horizontal, ExperimentalUITheme.Spacing.md)
        }
    }
}

// MARK: - File Row
struct ExperimentalFileRow: View {
    let index: Int
    let folder: ExperimentalFilesView.FileFolder
    
    var body: some View {
        HStack(spacing: ExperimentalUITheme.Spacing.md) {
            // File Icon
            ZStack {
                RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.sm)
                    .fill(ExperimentalUITheme.Gradients.accent.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: fileIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(ExperimentalUITheme.Colors.accentPrimary)
            }
            
            // File Info
            VStack(alignment: .leading, spacing: 4) {
                Text("File_\(index + 1).ipa")
                    .font(ExperimentalUITheme.Typography.callout)
                    .foregroundStyle(ExperimentalUITheme.Colors.textPrimary)
                
                Text("\(Int.random(in: 5...50)) MB")
                    .font(ExperimentalUITheme.Typography.caption)
                    .foregroundStyle(ExperimentalUITheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ExperimentalUITheme.Colors.textTertiary)
            }
        }
        .padding(ExperimentalUITheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: ExperimentalUITheme.CornerRadius.md)
                .fill(ExperimentalUITheme.Colors.backgroundSecondary)
        )
    }
    
    var fileIcon: String {
        switch folder {
        case .archives: return "archivebox.fill"
        case .signed: return "checkmark.seal.fill"
        case .unsigned: return "doc.fill"
        default: return "doc.zipper"
        }
    }
}
