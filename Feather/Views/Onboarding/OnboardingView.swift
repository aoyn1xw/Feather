import SwiftUI
import NimbleViews

@available(iOS 17.0, *)
struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Feather",
            description: "Your all-in-one app for sideloading iOS applications",
            imageName: "AppIcon60x60", // We'll try to use the app icon or a symbol
            isSystemImage: false
        ),
        OnboardingPage(
            title: "Browse Sources",
            description: "Add AltStore repositories and discover thousands of apps",
            imageName: "square.stack.3d.up.fill",
            isSystemImage: true
        ),
        OnboardingPage(
            title: "Sign Apps",
            description: "Sign IPA files with your certificates or use our remote signing service",
            imageName: "signature",
            isSystemImage: true
        )
    ]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                VStack(spacing: 20) {
                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.accentColor : Color.secondary.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Button
                    Button {
                        withAnimation {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                hasCompletedOnboarding = true
                            }
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let isSystemImage: Bool
}

@available(iOS 17.0, *)
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if page.isSystemImage {
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundStyle(.tint)
                    .symbolEffect(.bounce, value: true)
            } else {
                // Use AppIconView to get the app icon
                Image(uiImage: AppIconView.altImage(nil))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(22)
            }
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding()
    }
}

@available(iOS 17.0, *)
#Preview {
    OnboardingView()
}

// MARK: - Legacy iOS 16 Support
struct OnboardingViewLegacy: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentPage = 0
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to Feather",
            description: "Your all-in-one app for sideloading iOS applications",
            imageName: "AppIcon60x60",
            isSystemImage: false
        ),
        OnboardingPage(
            title: "Browse Sources",
            description: "Add AltStore repositories and discover thousands of apps",
            imageName: "square.stack.3d.up.fill",
            isSystemImage: true
        ),
        OnboardingPage(
            title: "Sign Apps",
            description: "Sign IPA files with your certificates or use our remote signing service",
            imageName: "signature",
            isSystemImage: true
        )
    ]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageViewLegacy(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                VStack(spacing: 20) {
                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.accentColor : Color.secondary.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Button
                    Button {
                        withAnimation {
                            if currentPage < pages.count - 1 {
                                currentPage += 1
                            } else {
                                hasCompletedOnboarding = true
                            }
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct OnboardingPageViewLegacy: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if page.isSystemImage {
                Image(systemName: page.imageName)
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
            } else {
                // Use AppIconView to get the app icon
                Image(uiImage: AppIconView.altImage(nil))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .cornerRadius(22)
            }
            
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .padding()
    }
}
