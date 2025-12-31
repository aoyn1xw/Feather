import SwiftUI
import NimbleViews

struct SigningProcessView: View {
    @Environment(\.dismiss) var dismiss
    @State private var progress: Double = 0.0
    @State private var logs: [String] = []
    @State private var currentStep: String = "Initializing..."
    @State private var isFinished = false
    
    var appName: String
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "signature")
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                        .symbolEffect(.bounce, value: progress)
                    
                    Text("Signing \(appName)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(currentStep)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 60)
                
                // Progress
                VStack(spacing: 8) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .tint(.accentColor)
                    
                    HStack {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .monospacedDigit()
                        Spacer()
                    }
                }
                .padding(.horizontal, 40)
                
                // Logs
                VStack(alignment: .leading) {
                    Text("Logs")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(logs, id: \.self) { log in
                                Text(log)
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal)
                
                Spacer()
                
                if isFinished {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            startSigningSimulation()
        }
    }
    
    func startSigningSimulation() {
        // Simulate signing process
        let steps = [
            "Extracting IPA...",
            "Verifying entitlements...",
            "Patching binary...",
            "Signing frameworks...",
            "Signing application...",
            "Packaging...",
            "Done!"
        ]
        
        Task {
            for (index, step) in steps.enumerated() {
                try? await Task.sleep(nanoseconds: 800_000_000) // 0.8s delay
                await MainActor.run {
                    currentStep = step
                    logs.append("[\(Date().formatted(date: .omitted, time: .standard))] \(step)")
                    withAnimation {
                        progress = Double(index + 1) / Double(steps.count)
                    }
                }
            }
            await MainActor.run {
                isFinished = true
            }
        }
    }
}
