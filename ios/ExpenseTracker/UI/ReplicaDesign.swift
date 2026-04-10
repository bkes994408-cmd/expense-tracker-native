import SwiftUI

enum ReplicaDesign {
    static let cardRadius: CGFloat = 22
    static let cardBorder = Color(red: 228/255, green: 233/255, blue: 245/255)
    static let cardShadow = Color.black.opacity(0.06)
    static let sectionSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let rowBg = Color(red: 247/255, green: 248/255, blue: 255/255)
    static let rowBorder = Color(red: 232/255, green: 236/255, blue: 246/255)
}

struct ReplicaCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(.white, in: RoundedRectangle(cornerRadius: ReplicaDesign.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ReplicaDesign.cardRadius, style: .continuous)
                    .stroke(ReplicaDesign.cardBorder, lineWidth: 1)
            )
            .shadow(color: ReplicaDesign.cardShadow, radius: 8, y: 4)
    }
}

extension View {
    func replicaCard() -> some View {
        modifier(ReplicaCardModifier())
    }
}

struct ReplicaStateBox: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 59/255, green: 71/255, blue: 112/255))
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(red: 246/255, green: 248/255, blue: 255/255), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(ReplicaDesign.cardBorder, lineWidth: 1)
        )
    }
}

struct ReplicaListRow: View {
    let title: String
    let subtitle: String?
    let trailing: String?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(red: 74/255, green: 86/255, blue: 128/255))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(ReplicaDesign.rowBg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(ReplicaDesign.rowBorder, lineWidth: 1)
        )
    }
}

struct ReplicaEdgeStates: View {
    let loadingMessage: String
    let emptyMessage: String
    let errorMessage: String
    let longTextMessage: String
    let denseContentHint: String

    var body: some View {
        VStack(spacing: 12) {
            ReplicaStateBox(title: "Loading", message: loadingMessage)
            ReplicaStateBox(title: "Empty", message: emptyMessage)
            ReplicaStateBox(title: "Error", message: errorMessage)
            ReplicaStateBox(title: "Long text", message: longTextMessage)
            ReplicaStateBox(title: "Dense content", message: denseContentHint)
        }
    }
}
