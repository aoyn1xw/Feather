import SwiftUI
import NimbleViews

// MARK: - ModernImportURLView
struct ModernImportURLView: View {
    @Environment(\.dismiss) var dismiss
    @State private var urlText = ""
    @FocusState private var isTextFieldFocused: Bool
    var onImport: (URL) -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.1),
                        Color.accentColor.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.accentColor.opacity(0.2),
                                        Color.accentColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.top, 30)
                    
                    VStack(spacing: 8) {
                        Text(.localized("Import from URL"))
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                        
                        Text(.localized("Enter the URL of the IPA file you want to import"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // URL Input Field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "globe")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 18))
                            
                            TextField(.localized("https://example.com/app.ipa"), text: $urlText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.URL)
                                .focused($isTextFieldFocused)
                                .submitLabel(.done)
                                .onSubmit {
                                    handleImport()
                                }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(uiColor: .secondarySystemGroupedBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(isTextFieldFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            handleImport()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 18))
                                Text(.localized("Import"))
                                    .font(.headline)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(urlText.isEmpty)
                        .opacity(urlText.isEmpty ? 0.5 : 1.0)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text(.localized("Cancel"))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    private func handleImport() {
        guard !urlText.isEmpty, let url = URL(string: urlText) else { return }
        HapticsManager.shared.impact()
        onImport(url)
        dismiss()
    }
}
