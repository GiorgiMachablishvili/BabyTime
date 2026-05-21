import UIKit

// MARK: - BabyProfile model

struct BabyProfile: Codable {
    var id: String
    var name: String
    var birthdayTimestamp: Double?
    var gender: String
    var photoData: Data?

    init(id: String = UUID().uuidString,
         name: String = "",
         birthdayTimestamp: Double? = nil,
         gender: String = "Other",
         photoData: Data? = nil) {
        self.id = id
        self.name = name
        self.birthdayTimestamp = birthdayTimestamp
        self.gender = gender
        self.photoData = photoData
    }

    var birthday: Date? {
        get { birthdayTimestamp.map { Date(timeIntervalSince1970: $0) } }
        set { birthdayTimestamp = newValue?.timeIntervalSince1970 }
    }

    var photo: UIImage? {
        photoData.flatMap { UIImage(data: $0) }
    }
}

// MARK: - BabyProfileStore

enum BabyProfileStore {

    private static let defaults = UserDefaults.standard

    // Multi-profile keys
    private static let profilesKey      = "baby_profiles_v2"
    private static let selectedIndexKey = "baby_selected_profile_index"

    // Legacy single-profile keys (for migration on first launch)
    private enum Legacy {
        static let name     = "baby_profile.name"
        static let birthday = "baby_profile.birthday_time_interval"
        static let gender   = "baby_profile.gender"
        static let photo    = "baby_profile.photo_jpeg_data"
    }

    // MARK: - Multi-profile API

    static func loadProfiles() -> [BabyProfile] {
        if let data = defaults.data(forKey: profilesKey),
           let profiles = try? JSONDecoder().decode([BabyProfile].self, from: data),
           !profiles.isEmpty {
            return profiles
        }
        // Migrate legacy single profile on first launch
        var legacy = BabyProfile(
            name:    defaults.string(forKey: Legacy.name) ?? "",
            gender:  defaults.string(forKey: Legacy.gender) ?? "Other"
        )
        if let ts = defaults.object(forKey: Legacy.birthday) as? Double {
            legacy.birthdayTimestamp = ts
        }
        legacy.photoData = defaults.data(forKey: Legacy.photo)
        return [legacy]
    }

    static func saveProfiles(_ profiles: [BabyProfile]) {
        guard let data = try? JSONEncoder().encode(profiles) else { return }
        defaults.set(data, forKey: profilesKey)
    }

    static func selectedIndex() -> Int {
        let idx = defaults.integer(forKey: selectedIndexKey)
        return min(idx, max(0, loadProfiles().count - 1))
    }

    static func setSelectedIndex(_ index: Int) {
        defaults.set(index, forKey: selectedIndexKey)
    }

    static func currentProfile() -> BabyProfile? {
        let profiles = loadProfiles()
        let idx = selectedIndex()
        guard idx < profiles.count else { return profiles.first }
        return profiles[idx]
    }

    // MARK: - Convenience single-profile API (delegates to selected profile)

    static func saveName(_ name: String?) {
        var profiles = loadProfiles()
        let idx = selectedIndex()
        guard idx < profiles.count else { return }
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        profiles[idx].name = trimmed
        saveProfiles(profiles)
    }

    static func loadName() -> String? {
        let name = currentProfile()?.name
        return (name?.isEmpty == false) ? name : nil
    }

    static func saveBirthday(_ date: Date?) {
        var profiles = loadProfiles()
        let idx = selectedIndex()
        guard idx < profiles.count else { return }
        profiles[idx].birthdayTimestamp = date?.timeIntervalSince1970
        saveProfiles(profiles)
    }

    static func loadBirthday() -> Date? {
        currentProfile()?.birthday
    }

    static func saveGender(_ gender: String?) {
        var profiles = loadProfiles()
        let idx = selectedIndex()
        guard idx < profiles.count else { return }
        profiles[idx].gender = gender ?? "Other"
        saveProfiles(profiles)
    }

    static func loadGender() -> String? {
        currentProfile()?.gender
    }

    static func savePhoto(_ image: UIImage?) {
        var profiles = loadProfiles()
        let idx = selectedIndex()
        guard idx < profiles.count else { return }
        profiles[idx].photoData = image?.jpegData(compressionQuality: 0.85)
        saveProfiles(profiles)
    }

    static func loadPhoto() -> UIImage? {
        currentProfile()?.photo
    }
}
