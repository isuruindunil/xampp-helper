import SwiftUI

public struct StatusBadge: View {
    public let state: ServiceState
    @State private var isPulsing: Bool = false

    public init(state: ServiceState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 6) {
            ZStack {
                if state == .running {
                    Circle()
                        .fill(state.color.opacity(0.35))
                        .frame(width: 14, height: 14)
                        .scaleEffect(isPulsing ? 1.4 : 0.8)
                        .opacity(isPulsing ? 0 : 0.9)
                        .animation(
                            .easeInOut(duration: 1.8).repeatForever(autoreverses: false),
                            value: isPulsing
                        )
                }

                Circle()
                    .fill(state.color)
                    .frame(width: 7, height: 7)
                    .shadow(color: state.color.opacity(0.7), radius: state == .running ? 3 : 0)
            }
            .frame(width: 14, height: 14)

            Text(state.title)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(state == .running ? .primary : .secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(state.color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .strokeBorder(state.color.opacity(0.3), lineWidth: 0.8)
        )
        .onAppear {
            if state == .running {
                isPulsing = true
            }
        }
        .onChange(of: state) { _, newState in
            isPulsing = (newState == .running)
        }
    }
}
