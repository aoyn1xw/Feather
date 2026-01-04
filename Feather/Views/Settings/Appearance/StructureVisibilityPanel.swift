import SwiftUI

// MARK: - Left Panel: Structure & Visibility
struct StructureVisibilityPanel: View {
    @ObservedObject var viewModel: StatusBarViewModel
    
    var body: some View {
        List {
            Section(header: Text("Visibility")) {
                Toggle("Show Custom Text", isOn: $viewModel.showCustomText)
                Toggle("Show SF Symbol", isOn: $viewModel.showSFSymbol)
                Toggle("Show Background", isOn: $viewModel.showBackground)
            }
            
            Section(header: Text("Layout")) {
                Picker("Alignment", selection: $viewModel.alignment) {
                    Text("Leading").tag("leading")
                    Text("Center").tag("center")
                    Text("Trailing").tag("trailing")
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Left")
                            .frame(width: 60, alignment: .leading)
                        Slider(value: $viewModel.leftPadding, in: 0...50, step: 1)
                        Text("\(Int(viewModel.leftPadding))")
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Right")
                            .frame(width: 60, alignment: .leading)
                        Slider(value: $viewModel.rightPadding, in: 0...50, step: 1)
                        Text("\(Int(viewModel.rightPadding))")
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Top")
                            .frame(width: 60, alignment: .leading)
                        Slider(value: $viewModel.topPadding, in: 0...50, step: 1)
                        Text("\(Int(viewModel.topPadding))")
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Bottom")
                            .frame(width: 60, alignment: .leading)
                        Slider(value: $viewModel.bottomPadding, in: 0...50, step: 1)
                        Text("\(Int(viewModel.bottomPadding))")
                            .frame(width: 40, alignment: .trailing)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section(header: Text("Animation")) {
                Toggle("Enable Animation", isOn: $viewModel.enableAnimation)
                
                if viewModel.enableAnimation {
                    Picker("Animation Type", selection: $viewModel.animationType) {
                        Text("None").tag("none")
                        Text("Bounce").tag("bounce")
                        Text("Fade").tag("fade")
                        Text("Slide").tag("slide")
                        Text("Scale").tag("scale")
                    }
                }
            }
            
            Section(header: Text("System Integration")) {
                Toggle("Hide Default Status Bar", isOn: $viewModel.hideDefaultStatusBar)
                    .onChange(of: viewModel.hideDefaultStatusBar) { _ in
                        NotificationCenter.default.post(name: NSNotification.Name("StatusBarHidingPreferenceChanged"), object: nil)
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
}
