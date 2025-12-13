import SwiftUI

struct ContentView: View {
    @State private var showPopup = false
    @State private var popupKind: PopupKind = .clipName
    @State private var inputText: String = ""
    @Environment(\.colorScheme) private var colorScheme

    // ✅ Navigation flags
    @State private var goToCamera = false
    @State private var goToLibrary = false

    // ✅ Use the shared store instead of local state arrays
    @EnvironmentObject var store: ClipsStore

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
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

                // 🔍 Hidden NavigationLink that listens to `goToCamera`
                NavigationLink(
                    destination: CameraView(),
                    isActive: $goToCamera
                ) {
                    EmptyView()
                }
                NavigationLink(
                    destination: LibraryView(allClips: $store.clips, categories: $store.categories),
                    isActive: $goToLibrary
                ) {
                    EmptyView()
                }
                .hidden()

                VStack(spacing: 10) {

                    // Logo (light/dark)
                    Image(colorScheme == .light ? "LogoLight" : "LogoDark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .clipShape(Circle())
                        .padding(.top, 100)

                    Spacer()

                    // 📸 مترجم — now actually navigates
                    AppButton(
                        title: "المترجم",
                        iconName: "camera.viewfinder",
                        type: .systemWhite
                    ) {
                        goToCamera = true
                    }

                    // 📚 Library button
                    AppButton(
                        title: "المكتبة",
                        iconName: "books.vertical.fill",
                        type: .systemBlack
                    ) {
                        goToLibrary = true
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ClipsStore())
}
