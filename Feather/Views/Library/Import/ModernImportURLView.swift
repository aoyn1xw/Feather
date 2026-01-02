import SwiftUI
import NimbleViews

// MARK: - ModernImportURLView
struct ModernImportURLView: View {
    @Environment(\.dismiss) var dismiss
    @State private var urlText = ""
    @FocusState private var isTextFieldFocused: Bool
	@State private var errorMessage: String?
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
								.onChange(of: urlText) { _ in
									errorMessage = nil
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
                                .stroke(errorMessage != nil ? Color.red : (isTextFieldFocused ? Color.accentColor : Color.clear), lineWidth: 2)
                        )
						
						if let errorMessage = errorMessage {
							HStack(spacing: 6) {
								Image(systemName: "exclamationmark.triangle.fill")
									.font(.caption)
								Text(errorMessage)
									.font(.caption)
							}
							.foregroundStyle(.red)
						}
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
		// Clear any previous errors
		errorMessage = nil
		
		// Check if empty
		guard !urlText.isEmpty else {
			errorMessage = "Please enter a URL"
			HapticsManager.shared.error()
			return
		}
		
		// Check if valid URL format
		guard let url = URL(string: urlText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
			errorMessage = "Invalid URL format"
			HapticsManager.shared.error()
			return
		}
		
		// Check if it has a scheme (http/https)
		guard let scheme = url.scheme, ["http", "https"].contains(scheme.lowercased()) else {
			errorMessage = "URL must start with http:// or https://"
			HapticsManager.shared.error()
			return
		}
		
		// Check if it has a host
		guard url.host != nil else {
			errorMessage = "Invalid URL - missing host"
			HapticsManager.shared.error()
			return
		}
		
		// Check if it ends with .ipa or .tipa
		let pathExtension = url.pathExtension.lowercased()
		guard pathExtension == "ipa" || pathExtension == "tipa" else {
			errorMessage = "URL must point to an .ipa or .tipa file"
			HapticsManager.shared.error()
			return
		}
		
        HapticsManager.shared.impact()
        onImport(url)
        dismiss()
    }
}
