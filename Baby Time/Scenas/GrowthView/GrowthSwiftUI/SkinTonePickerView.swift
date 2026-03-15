import SwiftUI

/// Reusable skin tone picker: row of round color circles. Selected index is bound; avatar preview can sit next to it.
struct SkinTonePickerView: View {
    @Binding var selectedIndex: Int
    var circleSize: CGFloat = 28

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<GrowthColors.skinTones.count, id: \.self) { index in
                Button {
                    selectedIndex = index
                } label: {
                    Circle()
                        .fill(GrowthColors.skinTones[index])
                        .frame(width: circleSize, height: circleSize)
                        .overlay(
                            Circle()
                                .stroke(selectedIndex == index ? GrowthColors.accent : Color.clear, lineWidth: 3)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#if DEBUG
struct SkinTonePickerView_Previews: PreviewProvider {
    static var previews: some View {
        SkinTonePickerView(selectedIndex: .constant(1))
            .padding()
    }
}
#endif
