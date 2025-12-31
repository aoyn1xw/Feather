//
//  InstallationView.swift
//  Feather
//
//  Created by samara on 3.06.2025.
//

import SwiftUI
import NimbleViews

// MARK: - View
struct InstallationView: View {
	@AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
	
	// MARK: Body
    var body: some View {
		NBList(.localized("Installation")) {
			ServerView()
		}
    }
}
