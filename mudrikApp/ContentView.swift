import SwiftUI

struct ContentView: View {
    @State private var showPopup = false
    @State private var popupKind: PopupKind = .clipName
    @State private var inputText: String = ""
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        // NavigationStack wraps the entire screen
        NavigationStack {
            ZStack {
                // Background gradient for the whole page
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(uiColor: .systemBackground), location: 0.0),
                        .init(color: Color(uiColor: .systemBackground), location: 0.7),
                        .init(color: .orange, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 10) {
                    
                    // App Logo (changes based on system appearance)
                    Image(colorScheme == .light ? "LogoLight" : "LogoDark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .clipShape(Circle())
                        .padding(.top, 100)
                    
                    
                    // ⚠️ Temporary navigation button — for testing only
                    NavigationLink {
                        CameraView()
                    } label: {
                        Text("Go to CameraView")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    // ⚠️ End of temporary navigation
                    
                    
                    Spacer()
                    
                    // Translator button
                    AppButton(
                        title: "المترجم",
                        iconName: "camera.viewfinder",
                        type: .systemWhite
                    ) {
                        print("Translator tapped")
                    }
                    
                    // Library button
                    AppButton(
                        title: "المكتبة",
                        iconName: "books.vertical.fill",
                        type: .systemBlack
                    ) {
                        print("Library tapped")
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
