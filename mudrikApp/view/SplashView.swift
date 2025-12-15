import SwiftUI

struct BlurryOrbBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Base color
                (colorScheme == .dark ? Color.black : Color.white)
                    .ignoresSafeArea()

                // MARK: - Large background orbs
                orb(.orange, opacity: dark(0.55, 0.35),
                    size: geo.size.width * 0.85,
                    from: (-0.35, -0.25), to: (0.25, 0.15), duration: 30)

                orb(.black, opacity: dark(0.40, 0.15),
                    size: geo.size.width * 0.90,
                    from: (0.30, 0.40), to: (0.45, 0.15), duration: 36)

                orb(.white, opacity: dark(0.22, 0.35),
                    size: geo.size.width * 0.70,
                    from: (0.45, -0.30), to: (0.15, 0.10), duration: 28)

                // MARK: - Mid layer orbs
                orb(.orange, opacity: dark(0.40, 0.28),
                    size: geo.size.width * 0.55,
                    from: (-0.15, 0.35), to: (0.10, 0.45), duration: 24)

                orb(.white, opacity: dark(0.16, 0.28),
                    size: geo.size.width * 0.50,
                    from: (0.50, 0.05), to: (0.35, 0.30), duration: 26)

                orb(.black, opacity: dark(0.30, 0.12),
                    size: geo.size.width * 0.60,
                    from: (0.10, -0.40), to: (0.25, -0.10), duration: 32)

                // MARK: - Small accent orbs
                orb(.orange, opacity: dark(0.35, 0.22),
                    size: geo.size.width * 0.35,
                    from: (-0.25, 0.15), to: (-0.05, 0.30), duration: 20)

                orb(.white, opacity: dark(0.12, 0.22),
                    size: geo.size.width * 0.30,
                    from: (0.35, -0.05), to: (0.20, 0.15), duration: 22)

                orb(.black, opacity: dark(0.25, 0.10),
                    size: geo.size.width * 0.40,
                    from: (-0.10, -0.50), to: (0.05, -0.25), duration: 34)

                orb(.orange, opacity: dark(0.28, 0.18),
                    size: geo.size.width * 0.28,
                    from: (0.55, 0.40), to: (0.40, 0.55), duration: 18)
            }
            .blur(radius: 55)
            .saturation(1.1)
            .onAppear { animate = true }
        }
    }

    // MARK: - Orb builder
    private func orb(
        _ color: Color,
        opacity: Double,
        size: CGFloat,
        from: (CGFloat, CGFloat),
        to: (CGFloat, CGFloat),
        duration: Double
    ) -> some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
            .offset(
                x: animate ? to.0 * size : from.0 * size,
                y: animate ? to.1 * size : from.1 * size
            )
            .animation(
                .easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: animate
            )
            .blendMode(.plusLighter)
    }

    private func dark(_ dark: Double, _ light: Double) -> Double {
        colorScheme == .dark ? dark : light
    }
}

// MARK: - Your SplashView with the background
struct SplashView: View {
    @State private var animate = false
    @State private var navigate = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // ✅ Animated blurry background
            BlurryOrbBackground()

            VStack(alignment: .center, spacing: 20) {
                Spacer()

                ZStack(alignment: .center) {
                    Image(colorScheme == .light ? "LogoLight" : "LogoDark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400)
                        .offset(y: animate ? -10 : 0)
                        .opacity(animate ? 1 : 0.5)
                        .animation(.easeInOut(duration: 1.8).repeatForever(), value: animate)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            animate = true

            // Auto navigate after 2.3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                navigate = true
            }
        }
        .fullScreenCover(isPresented: $navigate) {
            ContentView()
        }
    }
}

#Preview {
    SplashView()
}
