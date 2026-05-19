import SwiftUI

/// Main Growth screen: height comparison visualization + plus button. Sheet for input.
struct GrowthMainView: View {
    @ObservedObject var viewModel: GrowthComparisonViewModel
    @State private var showAddSheet = false
    @State private var listRefreshId = UUID()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 20) {
                    comparisonCard
                    historyCard
                }
                .padding()
                .padding(.top, 8)
                .id(listRefreshId)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(GrowthColors.background)

            Button {
                showAddSheet = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(GrowthColors.accent)
            }
            .padding(.trailing, 20)
            .padding(.top, 12)
        }
        .sheet(isPresented: $showAddSheet, onDismiss: {
            viewModel.load()
            listRefreshId = UUID()
        }) {
            AddHeightComparisonView(viewModel: viewModel)
        }
    }

    private var comparisonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Height comparison")
                .font(.headline)
                .foregroundColor(GrowthColors.textPrimary)

            if hasAnyHeight {
                HeightComparisonVisualView(data: viewModel.data)
            } else {
                emptyState
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GrowthColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private var hasAnyHeight: Bool {
        let d = viewModel.data
        return (d.babyHeightCm ?? 0) > 0 || (d.parent1HeightCm ?? 0) > 0 || (d.parent2HeightCm ?? 0) > 0
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "ruler")
                .font(.system(size: 44))
                .foregroundStyle(GrowthColors.accent.opacity(0.8))
            Text("Add heights to compare")
                .font(.subheadline)
                .foregroundColor(GrowthColors.textSecondary)
            Text("Tap the + button to enter parent and baby heights.")
                .font(.caption)
                .foregroundColor(GrowthColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
                .foregroundColor(GrowthColors.textPrimary)
            if viewModel.history.isEmpty {
                Text("No saved entries yet. Save from the height comparison form to add history.")
                    .font(.subheadline)
                    .foregroundColor(GrowthColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                List {
                    ForEach(viewModel.history) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Baby height")
                                    .font(.caption)
                                    .foregroundColor(GrowthColors.textSecondary)
                                Text(formatBabyHeight(entry.babyHeightCm))
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(GrowthColors.textPrimary)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Saved")
                                    .font(.caption)
                                    .foregroundColor(GrowthColors.textSecondary)
                                Text(GrowthMainView.formatHistoryDate(entry.savedAt))
                                    .font(.subheadline)
                                    .foregroundColor(GrowthColors.textSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(GrowthColors.textSecondary.opacity(0.3))
                    }
                    .onDelete { viewModel.deleteHistoryEntries(atOffsets: $0) }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .id(viewModel.history.count)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GrowthColors.cardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    private func formatBabyHeight(_ cm: Double) -> String {
        if cm == floor(cm) { return "\(Int(cm)) cm" }
        return String(format: "%.1f cm", cm)
    }

    static func formatHistoryDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}

/// Visual: vertical scale and three vertical columns (bars) colored by skin tone, representing heights.
struct HeightComparisonVisualView: View {
    let data: GrowthComparisonData
    private let scaleHeight: CGFloat = 280
    private let columnCornerRadius: CGFloat = 12

    var body: some View {
        let p1 = data.parent1HeightCm ?? 0
        let p2 = data.parent2HeightCm ?? 0
        let baby = data.babyHeightCm ?? 0
        let maxH = max(p1, p2, baby, 1)

        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 12) {
                heightScaleView(maxHeight: maxH)
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(GrowthColors.background.opacity(0.6))
                        .frame(height: scaleHeight)
                    HStack(alignment: .bottom, spacing: 20) {
                        heightColumn(
                            heightCm: baby,
                            maxHeight: maxH,
                            color: GrowthColors.skinTones[data.babySkinToneIndex]
                        )
                        heightColumn(
                            heightCm: p1,
                            maxHeight: maxH,
                            color: GrowthColors.skinTones[data.parent1SkinToneIndex]
                        )
                        heightColumn(
                            heightCm: p2,
                            maxHeight: maxH,
                            color: GrowthColors.skinTones[data.parent2SkinToneIndex]
                        )
                    }
                    .padding(.horizontal, 16)
                }
                .frame(height: scaleHeight)
            }
            labelsRow(baby: baby, p1: p1, p2: p2)
        }
    }

    private func heightScaleView(maxHeight: Double) -> some View {
        let step = maxHeight > 100 ? 50.0 : (maxHeight > 50 ? 25.0 : 20.0)
        let ticks = stride(from: 0.0, through: maxHeight, by: step).map { $0 }
        return ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 8)
                .fill(GrowthColors.background.opacity(0.5))
                .frame(width: 36, height: scaleHeight)
            ForEach(Array(ticks.enumerated()), id: \.offset) { _, h in
                let y = h / max(maxHeight, 1) * scaleHeight
                Text("\(Int(h))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(GrowthColors.textSecondary)
                    .offset(y: -y + 8)
            }
        }
        .frame(width: 36, height: scaleHeight)
    }

    /// Vertical column (bar) filled with skin tone color; height proportional to person's height.
    private func heightColumn(heightCm: Double, maxHeight: Double, color: Color) -> some View {
        let barHeight: CGFloat = maxHeight > 0 && heightCm > 0
            ? CGFloat(heightCm / maxHeight) * scaleHeight
            : 0
        return VStack(spacing: 0) {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: columnCornerRadius)
                .fill(color)
                .frame(height: max(barHeight, 0))
        }
        .frame(maxWidth: .infinity)
        .frame(height: scaleHeight)
    }

    private func labelsRow(baby: Double, p1: Double, p2: Double) -> some View {
        HStack(spacing: 20) {
            labelBlock("Baby", height: baby)
            labelBlock(data.parent1Type.displayName, height: p1)
            labelBlock(data.parent2Type.displayName, height: p2)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
    }

    private func labelBlock(_ name: String, height: Double) -> some View {
        VStack(spacing: 2) {
            Text(height > 0 ? "\(Int(height)) cm" : "—")
                .font(.caption)
                .foregroundColor(GrowthColors.textSecondary)
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundColor(GrowthColors.textPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}

#if DEBUG
struct GrowthMainView_Previews: PreviewProvider {
    static var previews: some View {
        GrowthMainView(viewModel: GrowthComparisonViewModel(initialData: .sample))
    }
}
#endif
