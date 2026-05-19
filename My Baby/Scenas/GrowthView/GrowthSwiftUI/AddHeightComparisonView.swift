import SwiftUI

/// Input sheet: parent types, heights, skin tones. Save dismisses and updates the view model.
struct AddHeightComparisonView: View {
    @ObservedObject var viewModel: GrowthComparisonViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var parent1Type: GrowthComparisonData.ParentType
    @State private var parent2Type: GrowthComparisonData.ParentType
    @State private var parent1HeightText: String
    @State private var parent2HeightText: String
    @State private var babyHeightText: String
    @State private var parent1SkinIndex: Int
    @State private var parent2SkinIndex: Int
    @State private var babySkinIndex: Int

    init(viewModel: GrowthComparisonViewModel) {
        self.viewModel = viewModel
        let d = viewModel.data
        _parent1Type = State(initialValue: d.parent1Type)
        _parent2Type = State(initialValue: d.parent2Type)
        _parent1HeightText = State(initialValue: d.parent1HeightCm.map { "\(Int($0))" } ?? "")
        _parent2HeightText = State(initialValue: d.parent2HeightCm.map { "\(Int($0))" } ?? "")
        _babyHeightText = State(initialValue: d.babyHeightCm.map { "\(Int($0))" } ?? "")
        _parent1SkinIndex = State(initialValue: d.parent1SkinToneIndex)
        _parent2SkinIndex = State(initialValue: d.parent2SkinToneIndex)
        _babySkinIndex = State(initialValue: d.babySkinToneIndex)
    }

    private var parent1HeightCm: Double? { Double(parent1HeightText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")) }
    private var parent2HeightCm: Double? { Double(parent2HeightText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")) }
    private var babyHeightCm: Double? { Double(babyHeightText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")) }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    parentTypeSection
                    parent1Section
                    parent2Section
                    babySection
                }
                .padding()
            }
            .background(GrowthColors.background)
            .navigationTitle("Height comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var parentTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parent types")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(GrowthColors.textPrimary)
            HStack(spacing: 12) {
                parentTypePicker(title: "Parent 1", selection: $parent1Type)
                parentTypePicker(title: "Parent 2", selection: $parent2Type)
            }
        }
        .padding()
        .background(GrowthColors.cardBackground)
        .cornerRadius(16)
    }

    private func parentTypePicker(title: String, selection: Binding<GrowthComparisonData.ParentType>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(GrowthColors.textSecondary)
            Picker(title, selection: selection) {
                Text("Mother").tag(GrowthComparisonData.ParentType.mother)
                Text("Father").tag(GrowthComparisonData.ParentType.father)
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var parent1Section: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AvatarView(color: GrowthColors.skinTones[parent1SkinIndex], isBaby: false, size: 48)
                Text(parent1Type.displayName)
                    .font(.headline)
                    .foregroundColor(GrowthColors.textPrimary)
            }
            heightField(value: $parent1HeightText, placeholder: "Height (cm)")
            Text("Skin tone")
                .font(.caption)
                .foregroundColor(GrowthColors.textSecondary)
            SkinTonePickerView(selectedIndex: $parent1SkinIndex)
        }
        .padding()
        .background(GrowthColors.cardBackground)
        .cornerRadius(16)
    }

    private var parent2Section: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AvatarView(color: GrowthColors.skinTones[parent2SkinIndex], isBaby: false, size: 48)
                Text(parent2Type.displayName)
                    .font(.headline)
                    .foregroundColor(GrowthColors.textPrimary)
            }
            heightField(value: $parent2HeightText, placeholder: "Height (cm)")
            Text("Skin tone")
                .font(.caption)
                .foregroundColor(GrowthColors.textSecondary)
            SkinTonePickerView(selectedIndex: $parent2SkinIndex)
        }
        .padding()
        .background(GrowthColors.cardBackground)
        .cornerRadius(16)
    }

    private var babySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                AvatarView(color: GrowthColors.skinTones[babySkinIndex], isBaby: true, size: 48)
                Text("Baby")
                    .font(.headline)
                    .foregroundColor(GrowthColors.textPrimary)
            }
            heightField(value: $babyHeightText, placeholder: "Height (cm)")
            Text("Skin tone")
                .font(.caption)
                .foregroundColor(GrowthColors.textSecondary)
            SkinTonePickerView(selectedIndex: $babySkinIndex)
        }
        .padding()
        .background(GrowthColors.cardBackground)
        .cornerRadius(16)
    }

    private func heightField(value: Binding<String>, placeholder: String) -> some View {
        TextField(placeholder, text: value)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
    }

    private func saveAndDismiss() {
        let parsedBaby = Double(babyHeightText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
        viewModel.updateFromForm(
            parent1Type: parent1Type,
            parent2Type: parent2Type,
            parent1HeightCm: parent1HeightCm,
            parent2HeightCm: parent2HeightCm,
            babyHeightCm: babyHeightCm,
            parent1SkinToneIndex: parent1SkinIndex,
            parent2SkinToneIndex: parent2SkinIndex,
            babySkinToneIndex: babySkinIndex
        )
        if let babyCm = parsedBaby, babyCm >= 0 {
            viewModel.addHistoryEntry(babyHeightCm: babyCm)
        }
        dismiss()
    }
}

#if DEBUG
struct AddHeightComparisonView_Previews: PreviewProvider {
    static var previews: some View {
        AddHeightComparisonView(viewModel: GrowthComparisonViewModel(initialData: .sample))
    }
}
#endif
