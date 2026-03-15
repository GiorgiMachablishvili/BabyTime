import SwiftUI

/// Reusable avatar: circle with optional SF Symbol, filled with a background color (e.g. skin tone or teal for baby).
struct AvatarView: View {
    let color: Color
    var isBaby: Bool = false
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
            Image(systemName: isBaby ? "figure.child" : "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
    }
}

#if DEBUG
struct AvatarView_Previews: PreviewProvider {
    static var previews: some View {
        HStack(spacing: 20) {
            AvatarView(color: GrowthColors.growthTeal, isBaby: true)
            AvatarView(color: GrowthColors.skinTones[1], isBaby: false)
        }
        .padding()
    }
}
#endif
