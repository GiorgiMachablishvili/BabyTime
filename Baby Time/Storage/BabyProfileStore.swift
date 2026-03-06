import UIKit

enum BabyProfileStore {
    private static let defaults = UserDefaults.standard

    private enum Key {
        static let name = "baby_profile.name"
        static let birthdayTimeInterval = "baby_profile.birthday_time_interval"
        static let gender = "baby_profile.gender"
        static let photoJPEGData = "baby_profile.photo_jpeg_data"
    }

    static func saveName(_ name: String?) {
        let trimmed = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(trimmed.isEmpty ? nil : trimmed, forKey: Key.name)
    }

    static func loadName() -> String? {
        defaults.string(forKey: Key.name)
    }

    static func saveBirthday(_ date: Date?) {
        if let date {
            defaults.set(date.timeIntervalSince1970, forKey: Key.birthdayTimeInterval)
        } else {
            defaults.removeObject(forKey: Key.birthdayTimeInterval)
        }
    }

    static func loadBirthday() -> Date? {
        let value = defaults.object(forKey: Key.birthdayTimeInterval) as? Double
        guard let value else { return nil }
        return Date(timeIntervalSince1970: value)
    }

    static func saveGender(_ gender: String?) {
        let trimmed = (gender ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(trimmed.isEmpty ? nil : trimmed, forKey: Key.gender)
    }

    static func loadGender() -> String? {
        defaults.string(forKey: Key.gender)
    }

    static func savePhoto(_ image: UIImage?) {
        guard let image else {
            defaults.removeObject(forKey: Key.photoJPEGData)
            return
        }
        let data = image.jpegData(compressionQuality: 0.85)
        defaults.set(data, forKey: Key.photoJPEGData)
    }

    static func loadPhoto() -> UIImage? {
        guard let data = defaults.data(forKey: Key.photoJPEGData) else { return nil }
        return UIImage(data: data)
    }
}

