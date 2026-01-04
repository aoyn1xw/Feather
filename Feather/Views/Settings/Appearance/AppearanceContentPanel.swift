import SwiftUI

// MARK: - Right Panel: Appearance & Content
struct AppearanceContentPanel: View {
    @ObservedObject var viewModel: StatusBarViewModel
    @State private var showColorPicker = false
    @State private var showBackgroundColorPicker = false
    @State private var showShadowColorPicker = false
    @State private var showBorderColorPicker = false
    @State private var showSymbolPicker = false
    @State private var showTimeColorPicker = false
    @State private var showBatteryColorPicker = false
    
    var body: some View {
        List {
            // Content Section
            if viewModel.showCustomText {
                Section(header: Text("Custom Text")) {
                    TextField("Enter custom text", text: $viewModel.customText)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            if viewModel.showSFSymbol {
                Section(header: Text("SF Symbol")) {
                    HStack {
                        Text("Selected Symbol")
                        Spacer()
                        Image(systemName: viewModel.sfSymbol)
                            .font(.title2)
                        Text(viewModel.sfSymbol)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    
                    Button {
                        showSymbolPicker = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Browse Symbols")
                            Image(systemName: "magnifyingglass")
                            Spacer()
                        }
                    }
                }
            }
            
            // Styling Section
            Section(header: Text("Text Styling")) {
                Toggle("Bold", isOn: $viewModel.isBold)
                
                Picker("Font Design", selection: $viewModel.fontDesign) {
                    Text("Default").tag("default")
                    Text("Monospaced").tag("monospaced")
                    Text("Rounded").tag("rounded")
                    Text("Serif").tag("serif")
                }
                
                HStack {
                    Text("Font Size")
                    Spacer()
                    Text("\(Int(viewModel.fontSize)) pt")
                        .foregroundStyle(.secondary)
                }
                Slider(value: $viewModel.fontSize, in: 8...24, step: 1)
                
                Button {
                    showColorPicker = true
                } label: {
                    HStack {
                        Text("Text Color")
                        Spacer()
                        Circle()
                            .fill(Color(hex: viewModel.colorHex))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
            }
            
            // Background Section
            if viewModel.showBackground {
                Section(header: Text("Background")) {
                    Toggle("Blur Background", isOn: $viewModel.blurBackground)
                    
                    Button {
                        showBackgroundColorPicker = true
                    } label: {
                        HStack {
                            Text("Background Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.backgroundColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    HStack {
                        Text("Opacity")
                        Spacer()
                        Text("\(Int(viewModel.backgroundOpacity * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.backgroundOpacity, in: 0...1, step: 0.1)
                    
                    HStack {
                        Text("Corner Radius")
                        Spacer()
                        Text("\(Int(viewModel.cornerRadius)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.cornerRadius, in: 0...30, step: 1)
                    
                    HStack {
                        Text("Border Width")
                        Spacer()
                        Text("\(Int(viewModel.borderWidth)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.borderWidth, in: 0...5, step: 0.5)
                    
                    if viewModel.borderWidth > 0 {
                        Button {
                            showBorderColorPicker = true
                        } label: {
                            HStack {
                                Text("Border Color")
                                Spacer()
                                Circle()
                                    .fill(Color(hex: viewModel.borderColorHex))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                        }
                    }
                }
            }
            
            // Shadow Section
            Section(header: Text("Shadow")) {
                Toggle("Enable Shadow", isOn: $viewModel.shadowEnabled)
                
                if viewModel.shadowEnabled {
                    Button {
                        showShadowColorPicker = true
                    } label: {
                        HStack {
                            Text("Shadow Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.shadowColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    HStack {
                        Text("Shadow Radius")
                        Spacer()
                        Text("\(Int(viewModel.shadowRadius)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.shadowRadius, in: 0...20, step: 1)
                }
            }
            
            // Time Section
            Section(header: Text("Time Display")) {
                Toggle("Show Time", isOn: $viewModel.showTime)
                
                if viewModel.showTime {
                    Toggle("Show Seconds", isOn: $viewModel.showSeconds)
                    
                    Button {
                        showTimeColorPicker = true
                    } label: {
                        HStack {
                            Text("Time Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.timeColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            // Battery Section
            Section(header: Text("Battery Display")) {
                Toggle("Show Battery", isOn: $viewModel.showBattery)
                
                if viewModel.showBattery {
                    Picker("Battery Style", selection: $viewModel.batteryStyle) {
                        Text("Icon Only").tag("icon")
                        Text("Percentage Only").tag("percentage")
                        Text("Icon & Percentage").tag("both")
                    }
                    
                    Button {
                        showBatteryColorPicker = true
                    } label: {
                        HStack {
                            Text("Battery Color")
                            Spacer()
                            Circle()
                                .fill(Color(hex: viewModel.batteryColorHex))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            // Reset Section
            Section {
                Button(role: .destructive) {
                    viewModel.resetToDefaults()
                } label: {
                    HStack {
                        Spacer()
                        Text("Reset to Defaults")
                        Spacer()
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedColor, colorHex: $viewModel.colorHex)
        }
        .sheet(isPresented: $showBackgroundColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedBackgroundColor, colorHex: $viewModel.backgroundColorHex)
        }
        .sheet(isPresented: $showShadowColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedShadowColor, colorHex: $viewModel.shadowColorHex)
        }
        .sheet(isPresented: $showBorderColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedBorderColor, colorHex: $viewModel.borderColorHex)
        }
        .sheet(isPresented: $showTimeColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedTimeColor, colorHex: $viewModel.timeColorHex)
        }
        .sheet(isPresented: $showBatteryColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedBatteryColor, colorHex: $viewModel.batteryColorHex)
        }
        .sheet(isPresented: $showSymbolPicker) {
            SFSymbolsPickerView(viewModel: viewModel)
        }
    }
}
