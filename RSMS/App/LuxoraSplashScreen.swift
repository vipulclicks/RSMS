import SwiftUI

// MARK: - Splash Screen with Seamless Bubble Transition
// Strategy: The splash's ambient circles BECOME the login screen's decorative circles.
// The login card bubbles out from center during the transition.
// No hard cut — one continuous morphing scene.

struct LuxoraSplashScreen: View {

    // MARK: - Animation States

    // Phase 1: Splash logo entry
    @State private var animateLogo = false
    @State private var animateText = false

    // Phase 2: Pre-transition — circles begin drifting toward login positions
    @State private var circlesMorphing = false

    // Phase 3: Transition — login card bubbles in, splash branding fades out
    @State private var showLoginCard = false
    @State private var splashBrandingFades = false

    // Phase 4: Complete — splash chrome gone, fully in login view
    @State private var splashDone = false

    // MARK: - Theme
    let backgroundCream   = Color(red: 0.94, green: 0.89, blue: 0.84)
    let brandMaroon       = Color(red: 0.55, green: 0.23, blue: 0.31)
    let textMuted         = Color(red: 0.45, green: 0.35, blue: 0.35)
    let cardBackground    = Color.white

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Background ──────────────────────────────────────────────
                backgroundCream.ignoresSafeArea()

                // ── Circle 1 (top-left ambient → login position) ─────────────
                // Splash: large blurred blob top-left.
                // Login: smaller, crisper circle top-left.
                Circle()
                    .fill(
                        circlesMorphing
                            ? Color.white.opacity(0.6)          // login version: bright
                            : Color.white.opacity(0.5)          // splash version: soft
                    )
                    .frame(
                        width:  circlesMorphing ? 280 : 450,
                        height: circlesMorphing ? 280 : 450
                    )
                    .blur(radius: circlesMorphing ? 0 : 60)
                    .offset(
                        x: circlesMorphing ? -geo.size.width * 0.38 : -90,
                        y: circlesMorphing ? -geo.size.height * 0.38 : -180
                    )
                    .opacity(splashDone ? 0 : 1)
                    .animation(
                        .spring(response: 1.1, dampingFraction: 0.75).delay(0.1),
                        value: circlesMorphing
                    )

                // ── Circle 2 (bottom-right ambient → login position) ──────────
                Circle()
                    .fill(
                        circlesMorphing
                            ? brandMaroon.opacity(0.08)
                            : brandMaroon.opacity(0.04)
                    )
                    .frame(
                        width:  circlesMorphing ? 300 : 500,
                        height: circlesMorphing ? 300 : 500
                    )
                    .blur(radius: circlesMorphing ? 0 : 80)
                    .offset(
                        x: circlesMorphing ? geo.size.width * 0.38 : 130,
                        y: circlesMorphing ? geo.size.height * 0.38 : 220
                    )
                    .opacity(splashDone ? 0 : 1)
                    .animation(
                        .spring(response: 1.1, dampingFraction: 0.75).delay(0.0),
                        value: circlesMorphing
                    )

                // ── Splash Branding (logo + wordmark) ────────────────────────
                VStack(spacing: 24) {
                    // Diamond logo mark
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.65, green: 0.28, blue: 0.38), brandMaroon],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(45))
                        .scaleEffect(animateLogo ? 1.0 : 0.6)
                        .opacity(animateLogo ? 1.0 : 0.0)

                    VStack(spacing: 12) {
                        Text("Luxora")
                            .font(.system(size: 34, weight: .light, design: .serif))
                            .foregroundColor(brandMaroon)
                            .tracking(6)

                        Rectangle()
                            .fill(brandMaroon.opacity(0.4))
                            .frame(width: 65, height: 1.5)

                        Text("RETAIL STORE MANAGEMENT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(textMuted)
                            .tracking(3)
                    }
                    .opacity(animateText ? 1.0 : 0.0)
                    .offset(y: animateText ? 0 : 12)
                }
                // Branding fades out and scales down slightly during transition
                .opacity(splashBrandingFades ? 0 : 1)
                .scaleEffect(splashBrandingFades ? 0.88 : 1.0)
                .animation(
                    .easeInOut(duration: 0.55),
                    value: splashBrandingFades
                )

                // ── Login Card (bubbles in during transition) ─────────────────
                // Replace the content below with your real LoginView card body.
                // Keep this ZStack wrapper so the bubble-in animation works.
                if showLoginCard {
                    loginCardPlaceholder
                        .scaleEffect(showLoginCard ? 1.0 : 0.82)
                        .opacity(showLoginCard ? 1.0 : 0.0)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.82).combined(with: .opacity),
                                removal: .opacity
                            )
                        )
                }
            }
            .onAppear { runAnimationSequence() }
        }
    }

    // MARK: - Login Card Placeholder
    // 🔁 Replace this with your actual LoginView card content.
    private var loginCardPlaceholder: some View {
        VStack(spacing: 20) {
            Text("Luxora")
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(brandMaroon)
                .tracking(5)

            Text("Sign in to continue")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(textMuted)

            // Simulated fields
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(height: 48)
                .overlay(
                    HStack {
                        Text("Email")
                            .foregroundColor(textMuted.opacity(0.6))
                            .font(.system(size: 14))
                        Spacer()
                    }.padding(.horizontal, 16)
                )
                .shadow(color: brandMaroon.opacity(0.06), radius: 8, y: 3)

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .frame(height: 48)
                .overlay(
                    HStack {
                        Text("Password")
                            .foregroundColor(textMuted.opacity(0.6))
                            .font(.system(size: 14))
                        Spacer()
                    }.padding(.horizontal, 16)
                )
                .shadow(color: brandMaroon.opacity(0.06), radius: 8, y: 3)

            RoundedRectangle(cornerRadius: 10)
                .fill(brandMaroon)
                .frame(height: 48)
                .overlay(
                    Text("Sign In")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .tracking(1.5)
                )
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.85))
                .shadow(color: brandMaroon.opacity(0.12), radius: 30, y: 12)
        )
        .padding(.horizontal, 32)
    }

    // MARK: - Animation Sequence
    private func runAnimationSequence() {

        // ── Phase 1: Splash entry (0 – 1.5s) ───────────────────────────────
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            animateLogo = true
        }
        withAnimation(.easeOut(duration: 1.0).delay(0.7)) {
            animateText = true
        }

        // ── Phase 2: Circles start morphing toward login positions (2.0s) ──
        // Gives users ~1.5s to read the splash, then circles drift.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.75)) {
                circlesMorphing = true
            }
        }

        // ── Phase 3: Splash branding fades, card bubbles in (2.6s) ─────────
        // Slight delay after circles start moving so it feels staggered.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            withAnimation(.easeInOut(duration: 0.5)) {
                splashBrandingFades = true
            }
            // Card bubbles in with spring — feels organic, not mechanical
            withAnimation(.spring(response: 0.65, dampingFraction: 0.72).delay(0.1)) {
                showLoginCard = true
            }
        }

        // ── Phase 4: Mark transition complete (3.4s) ─────────────────────
        // At this point you can swap to a NavigationStack / full LoginView.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
            splashDone = true
        }
    }
}

// MARK: - Preview
#Preview {
    LuxoraSplashScreen()
}
