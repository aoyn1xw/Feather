import SwiftUI

// MARK: - Status Bar Preview (Read-Only)
struct StatusBarPreviewView: View {
    @ObservedObject var viewModel: StatusBarViewModel
    
    private var selectedFontDesign: Font.Design {
        switch viewModel.fontDesign {
        case "monospaced": return .monospaced
        case "rounded": return .rounded
        case "serif": return .serif
        default: return .default
        }
    }
    
    private var selectedAlignment: Alignment {
        switch viewModel.alignment {
        case "leading": return .leading
        case "trailing": return .trailing
        default: return .center
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Preview")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // iPhone mockup container
            ZStack {
                // iPhone shape
                RoundedRectangle(cornerRadius: 40)
                    .fill(Color(uiColor: .systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 2)
                    )
                    .frame(width: 300, height: 600)
                    .shadow(radius: 10)
                
                VStack(spacing: 0) {
                    // Status bar area with notch
                    ZStack(alignment: selectedAlignment) {
                        // Notch background
                        Color(uiColor: .systemBackground)
                            .frame(height: 50)
                        
                        // Background with shadow for better visibility
                        if viewModel.showBackground {
                            Group {
                                if viewModel.blurBackground {
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(
                                            Capsule()
                                                .fill(Color(hex: viewModel.backgroundColorHex).opacity(viewModel.backgroundOpacity))
                                        )
                                } else {
                                    Capsule()
                                        .fill(Color(hex: viewModel.backgroundColorHex).opacity(viewModel.backgroundOpacity))
                                }
                            }
                            .frame(width: 200)
                            .cornerRadius(viewModel.cornerRadius)
                            .overlay(
                                Capsule()
                                    .stroke(Color(hex: viewModel.borderColorHex), lineWidth: viewModel.borderWidth)
                                    .cornerRadius(viewModel.cornerRadius)
                            )
                            .shadow(
                                color: viewModel.shadowEnabled ? Color(hex: viewModel.shadowColorHex).opacity(0.3) : .clear,
                                radius: viewModel.shadowEnabled ? viewModel.shadowRadius : 0,
                                x: 0,
                                y: viewModel.shadowEnabled ? 2 : 0
                            )
                        }
                        
                        HStack(spacing: 8) {
                            if viewModel.showCustomText && !viewModel.customText.isEmpty {
                                Text(viewModel.customText)
                                    .font(.system(size: viewModel.fontSize, weight: viewModel.isBold ? .bold : .regular, design: selectedFontDesign))
                                    .foregroundStyle(Color(hex: viewModel.colorHex))
                                    .lineLimit(1)
                            }
                            
                            if viewModel.showSFSymbol && !viewModel.sfSymbol.isEmpty {
                                Image(systemName: viewModel.sfSymbol)
                                    .font(.system(size: viewModel.fontSize, weight: viewModel.isBold ? .bold : .regular, design: selectedFontDesign))
                                    .foregroundStyle(Color(hex: viewModel.colorHex))
                            }
                        }
                        .padding(.horizontal, viewModel.showBackground ? 12 : 0)
                        .padding(.vertical, viewModel.showBackground ? 6 : 0)
                        .padding(.leading, viewModel.leftPadding / 2)
                        .padding(.trailing, viewModel.rightPadding / 2)
                        .padding(.top, viewModel.topPadding / 2)
                        .padding(.bottom, viewModel.bottomPadding / 2)
                        .frame(maxWidth: .infinity, alignment: selectedAlignment)
                    }
                    .frame(height: 50)
                    
                    // iPhone content area
                    Rectangle()
                        .fill(Color(uiColor: .secondarySystemBackground).opacity(0.5))
                    
                    // Bottom safe area
                    Rectangle()
                        .fill(Color(uiColor: .systemBackground))
                        .frame(height: 30)
                }
                .frame(width: 280, height: 580)
                .clipShape(RoundedRectangle(cornerRadius: 35))
            }
            .allowsHitTesting(false) // Disable hit testing on the preview
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }
}
