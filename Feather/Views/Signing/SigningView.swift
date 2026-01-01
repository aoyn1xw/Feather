import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - View
struct SigningView: View {
	@Environment(\.dismiss) var dismiss
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
	@StateObject private var _optionsManager = OptionsManager.shared
	
	@State private var _temporaryOptions: Options = OptionsManager.shared.options
	@State private var _temporaryCertificate: Int
	@State private var _isAltPickerPresenting = false
	@State private var _isFilePickerPresenting = false
	@State private var _isImagePickerPresenting = false
	@State private var _isSigning = false
	@State private var _selectedPhoto: PhotosPickerItem? = nil
	@State var appIcon: UIImage?
	
	@State private var _isNameDialogPresenting = false
	@State private var _isIdentifierDialogPresenting = false
	@State private var _isVersionDialogPresenting = false
    @State private var _isSigningProcessPresented = false
	@State private var _isAddingCertificatePresenting = false
	
	// MARK: Fetch
	@FetchRequest(
		entity: CertificatePair.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
		animation: .easeInOut(duration: 0.35)
	) private var certificates: FetchedResults<CertificatePair>
	
	private func _selectedCert() -> CertificatePair? {
		guard certificates.indices.contains(_temporaryCertificate) else { return nil }
		return certificates[_temporaryCertificate]
	}
	
	var app: AppInfoPresentable
	
	init(app: AppInfoPresentable) {
		self.app = app
		let storedCert = UserDefaults.standard.integer(forKey: "feather.selectedCert")
		__temporaryCertificate = State(initialValue: storedCert)
	}
		
	// MARK: Body
    var body: some View {
		NBNavigationView(app.name ?? .localized("Unknown"), displayMode: .inline) {
			Form {
				_customizationOptions(for: app)
				_cert()
				_customizationProperties(for: app)
				
				// horrible
				Rectangle()
					.foregroundStyle(.clear)
					.frame(height: 30)
					.listRowBackground(EmptyView())
			}
			.overlay {
				VStack(spacing: 0) {
					Spacer()
					NBVariableBlurView()
						.frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 60 : 80)
						.rotationEffect(.degrees(180))
						.overlay {
							Button {
								_start()
							} label: {
								NBSheetButton(title: .localized("Start Signing"), style: .prominent)
									.padding()
							}
							.buttonStyle(.plain)
							.offset(y: UIDevice.current.userInterfaceIdiom == .pad ? -20 : -40)
						}
				}
				.ignoresSafeArea(edges: .bottom)
			}

			.toolbar {
				NBToolbarButton(role: .dismiss)
				NBToolbarButton(
					.localized("Reset"),
					style: .text,
					placement: .topBarTrailing
				) {
					_temporaryOptions = OptionsManager.shared.options
					appIcon = nil
				}
			}
			.sheet(isPresented: $_isAltPickerPresenting) { SigningAlternativeIconView(app: app, appIcon: $appIcon, isModifing: .constant(true)) }
			.sheet(isPresented: $_isFilePickerPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes:  [.image],
					onDocumentsPicked: { urls in
						guard let selectedFileURL = urls.first else { return }
						self.appIcon = UIImage.fromFile(selectedFileURL)?.resizeToSquare()
					}
				)
				.ignoresSafeArea()
			}
			.photosPicker(isPresented: $_isImagePickerPresenting, selection: $_selectedPhoto)
			.onChange(of: _selectedPhoto) { newValue in
				guard let newValue else { return }
				
				Task {
					if let data = try? await newValue.loadTransferable(type: Data.self),
					   let image = UIImage(data: data)?.resizeToSquare() {
						appIcon = image
					}
				}
			}
			.disabled(_isSigning)
			.animation(animationForPlatform(), value: _isSigning)
            .fullScreenCover(isPresented: $_isSigningProcessPresented) {
                if #available(iOS 17.0, *) {
                    SigningProcessView(appName: _temporaryOptions.appName ?? app.name ?? "App")
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Signing \( _temporaryOptions.appName ?? app.name ?? "App")...")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                }
            }
			.sheet(isPresented: $_isAddingCertificatePresenting) {
				CertificatesAddView()
					.presentationDetents([.medium])
			}
		}
		.alert(.localized("Name"), isPresented: $_isNameDialogPresenting) {
			TextField(_temporaryOptions.appName ?? (app.name ?? ""), text: Binding(
				get: { _temporaryOptions.appName ?? app.name ?? "" },
				set: { _temporaryOptions.appName = $0 }
			))
			.textInputAutocapitalization(.none)
			Button(.localized("Cancel"), role: .cancel) { }
			Button(.localized("Save")) { }
		}
		.alert(.localized("Identifier"), isPresented: $_isIdentifierDialogPresenting) {
			TextField(_temporaryOptions.appIdentifier ?? (app.identifier ?? ""), text: Binding(
				get: { _temporaryOptions.appIdentifier ?? app.identifier ?? "" },
				set: { _temporaryOptions.appIdentifier = $0 }
			))
			.textInputAutocapitalization(.none)
			Button(.localized("Cancel"), role: .cancel) { }
			Button(.localized("Save")) { }
		}
		.alert(.localized("Version"), isPresented: $_isVersionDialogPresenting) {
			TextField(_temporaryOptions.appVersion ?? (app.version ?? ""), text: Binding(
				get: { _temporaryOptions.appVersion ?? app.version ?? "" },
				set: { _temporaryOptions.appVersion = $0 }
			))
			.textInputAutocapitalization(.none)
			Button(.localized("Cancel"), role: .cancel) { }
			Button(.localized("Save")) { }
		}
		.onAppear {
			// ppq protection
			if
				_optionsManager.options.ppqProtection,
				let identifier = app.identifier,
				let cert = _selectedCert(),
				cert.ppQCheck
			{
				_temporaryOptions.appIdentifier = "\(identifier).\(_optionsManager.options.ppqString)"
			}
			
			if
				let currentBundleId = app.identifier,
				let newBundleId = _temporaryOptions.identifiers[currentBundleId]
			{
				_temporaryOptions.appIdentifier = newBundleId
			}
			
			if
				let currentName = app.name,
				let newName = _temporaryOptions.displayNames[currentName]
			{
				_temporaryOptions.appName = newName
			}
		}
    }
}

// MARK: - Extension: View
extension SigningView {
	@ViewBuilder
	private func _customizationOptions(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Customization")) {
			// Enhanced icon selection with glass effect
			Menu {
				Button(.localized("Select Alternative Icon"), systemImage: "app.dashed") { _isAltPickerPresenting = true }
				Button(.localized("Choose from Files"), systemImage: "folder") { _isFilePickerPresenting = true }
				Button(.localized("Choose from Photos"), systemImage: "photo") { _isImagePickerPresenting = true }
			} label: {
				ZStack {
					// Shadow layer
					Circle()
						.fill(Color.black.opacity(0.1))
						.frame(width: 60, height: 60)
						.blur(radius: 4)
						.offset(y: 3)
					
					if let icon = appIcon {
						Image(uiImage: icon)
							.appIconStyle()
							.shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
					} else {
						FRAppIconView(app: app, size: 56)
							.shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
					}
				}
			}
			
			_infoCell(.localized("Name"), desc: _temporaryOptions.appName ?? app.name, icon: "pencil") {
				_isNameDialogPresenting = true
			}
			_infoCell(.localized("Identifier"), desc: _temporaryOptions.appIdentifier ?? app.identifier, icon: "barcode") {
				_isIdentifierDialogPresenting = true
			}
			_infoCell(.localized("Version"), desc: _temporaryOptions.appVersion ?? app.version, icon: "tag") {
				_isVersionDialogPresenting = true
			}
		}
	}
	
	@ViewBuilder
	private func _cert() -> some View {
		NBSection(.localized("Signing")) {
			if let cert = _selectedCert() {
				NavigationLink {
					CertificatesView(selectedCert: $_temporaryCertificate)
				} label: {
					CertificatesCellView(
						cert: cert
					)
				}
			} else {
				VStack(spacing: 20) {
					HStack {
						ZStack {
							Circle()
								.fill(
									LinearGradient(
										colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
								.frame(width: 50, height: 50)
							
							Image(systemName: "exclamationmark.triangle.fill")
								.font(.title2)
								.foregroundStyle(
									LinearGradient(
										colors: [Color.orange, Color.orange.opacity(0.8)],
										startPoint: .topLeading,
										endPoint: .bottomTrailing
									)
								)
						}
						.shadow(color: Color.orange.opacity(0.3), radius: 8, x: 0, y: 4)
						
						VStack(alignment: .leading, spacing: 4) {
							Text(.localized("No Certificate"))
								.font(.headline)
								.foregroundColor(.primary)
							Text(.localized("Add a certificate to continue"))
								.font(.caption)
								.foregroundColor(.secondary)
						}
						Spacer()
					}
					.padding(.bottom, 8)
					
					Button {
						_isAddingCertificatePresenting = true
					} label: {
						HStack(spacing: 12) {
							ZStack {
								Circle()
									.fill(Color.accentColor.opacity(0.15))
									.frame(width: 36, height: 36)
								
								Image(systemName: "plus.circle.fill")
									.font(.title3)
									.foregroundStyle(
										LinearGradient(
											colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							}
							
							Text(.localized("Add Certificate"))
								.fontWeight(.semibold)
								.foregroundStyle(.primary)
							
							Spacer()
						}
						.frame(maxWidth: .infinity)
						.padding(.vertical, 16)
						.padding(.horizontal, 16)
						.background(
							ZStack {
								RoundedRectangle(cornerRadius: 16, style: .continuous)
									.fill(
										LinearGradient(
											colors: [
												Color.accentColor.opacity(0.15),
												Color.accentColor.opacity(0.08)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
								
								RoundedRectangle(cornerRadius: 16, style: .continuous)
									.stroke(
										LinearGradient(
											colors: [
												Color.accentColor.opacity(0.4),
												Color.accentColor.opacity(0.2)
											],
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										),
										lineWidth: 1.5
									)
							}
							.shadow(color: Color.accentColor.opacity(0.2), radius: 8, x: 0, y: 4)
						)
					}
					.buttonStyle(.plain)
				}
			}
		}
	}
	
	@ViewBuilder
	private func _customizationProperties(for app: AppInfoPresentable) -> some View {
		NBSection(.localized("Advanced")) {
			DisclosureGroup(
                content: {
                    NavigationLink {
                        SigningDylibView(
                            app: app,
                            options: $_temporaryOptions.optional()
                        )
                    } label: {
                        Label(.localized("Existing Dylibs"), systemImage: "puzzlepiece")
                    }
                    
                    NavigationLink {
                        SigningFrameworksView(
                            app: app,
                            options: $_temporaryOptions.optional()
                        )
                    } label: {
                        Label(.localized("Frameworks & PlugIns"), systemImage: "cube.box")
                    }
                    #if NIGHTLY || DEBUG
                    NavigationLink {
                        SigningEntitlementsView(
                            bindingValue: $_temporaryOptions.appEntitlementsFile
                        )
                    } label: {
                        Label(.localized("Entitlements") + " (BETA)", systemImage: "lock.shield")
                    }
                    #endif
                    NavigationLink {
                        SigningTweaksView(
                            options: $_temporaryOptions
                        )
                    } label: {
                        Label(.localized("Tweaks"), systemImage: "wrench.and.screwdriver")
                    }
                },
                label: {
                    Label(.localized("Modify"), systemImage: "hammer")
                }
            )
			
			NavigationLink {
				Form { SigningOptionsView(
					options: $_temporaryOptions,
					temporaryOptions: _optionsManager.options
				)}
				.navigationTitle(.localized("Properties"))
			} label: {
                Label(.localized("Properties"), systemImage: "slider.horizontal.3")
            }
		}
	}
	
	@ViewBuilder
	private func _infoCell(_ title: String, desc: String?, icon: String, action: @escaping () -> Void) -> some View {
		Button(action: action) {
			LabeledContent {
				Text(desc ?? .localized("Unknown"))
			} label: {
                Label(title, systemImage: icon)
            }
		}
		.buttonStyle(.plain)
	}
}

// MARK: - Extension: View (import)
extension SigningView {
	private func _start() {
		// CRITICAL: Check for .dylib files before signing
		if DylibDetector.shared.hasDylibs() {
			UIAlertController.showAlertWithOk(
				title: .localized("Dynamic Libraries Detected"),
				message: .localized("Sorry but you may not add any .dylib files to this app. Please resign the app without any additional frameworks to proceed.")
			)
			return
		}

		guard
			let cert = _selectedCert()
		else {
			UIAlertController.showAlertWithOk(
				title: .localized("No Certificate"),
				message: .localized("Please go to settings and import a valid certificate"),
				isCancel: true
			)
			return
		}

		HapticsManager.shared.impact()
		_isSigning = true
        _isSigningProcessPresented = true
		
        if _serverMethod == 2 {
            // Fully Remote
            FR.remoteSignPackageFile(
                app,
                using: _temporaryOptions,
                certificate: cert
            ) { result in
                _isSigningProcessPresented = false
                switch result {
                case .success(let installLink):
                    // Send notification if enabled
                    if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
                        NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App")
                    }
                    
                    let install = UIAlertAction(title: .localized("Install"), style: .default) { _ in
                        if let url = URL(string: installLink) {
                            UIApplication.shared.open(url)
                        }
                    }
                    let copy = UIAlertAction(title: .localized("Copy Link"), style: .default) { _ in
                        UIPasteboard.general.string = installLink
                    }
                    let cancel = UIAlertAction(title: .localized("Cancel"), style: .cancel)
                    
                    UIAlertController.showAlert(
                        title: .localized("Signing Successful"),
                        message: .localized("Your app is ready to install."),
                        actions: [install, copy, cancel]
                    )
                    
                case .failure(let error):
                    let ok = UIAlertAction(title: .localized("Dismiss"), style: .cancel)
                    UIAlertController.showAlert(
                        title: "Error",
                        message: error.localizedDescription,
                        actions: [ok]
                    )
                }
            }
        } else {
            // Local or Semi-Local
            FR.signPackageFile(
                app,
                using: _temporaryOptions,
                icon: appIcon,
                certificate: cert
            ) { error in
                if let error {
                    _isSigningProcessPresented = false
                    let ok = UIAlertAction(title: .localized("Dismiss"), style: .cancel) { _ in
                        dismiss()
                    }
                    
                    UIAlertController.showAlert(
                        title: "Error",
                        message: error.localizedDescription,
                        actions: [ok]
                    )
                } else {
                    if
                        _temporaryOptions.post_deleteAppAfterSigned,
                        !app.isSigned
                    {
                        Storage.shared.deleteApp(for: app)
                    }
                    
                    // Send notification if enabled
                    if UserDefaults.standard.bool(forKey: "Feather.notificationsEnabled") {
                        NotificationManager.shared.sendAppReadyNotification(appName: app.name ?? "App")
                    }
                    
                    if _temporaryOptions.post_installAppAfterSigned {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            NotificationCenter.default.post(name: Notification.Name("Feather.installApp"), object: nil)
                        }
                    }
                    dismiss()
                }
            }
        }
	}
    
    private func animationForPlatform() -> Animation {
        if #available(iOS 17.0, *) {
            return .smooth
        } else {
            return .easeInOut(duration: 0.35)
        }
    }
}
