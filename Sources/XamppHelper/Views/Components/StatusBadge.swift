import SwiftUI

public struct StatusBadge: View {
    public let state: ServiceState

    public init(state: ServiceState) {
        self.state = state
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(state.color)
                .frame(width: 8, height: 8)
                .shadow(color: state.color.opacity(0.6), radius: state == .running ? 3 : 0)

            Text(state.title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(state == .running ? .primary : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(state.color.opacity(0.12))
        )
        .overlay(
            Capsule()
                .strokeBorder(state.color.opacity(0.25), lineWidth: 0.8)
        )
    }
}

