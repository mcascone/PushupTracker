import SwiftUI

struct UndoBanner: View {
  let message: String
  let onUndo: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      Text(message)
        .font(.subheadline)
      Spacer()
      Button("Undo", action: onUndo)
        .buttonStyle(.borderedProminent)
        .controlSize(.small)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    .padding(.horizontal)
    .transition(.move(edge: .bottom).combined(with: .opacity))
  }
}
