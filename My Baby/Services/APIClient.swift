import UIKit

// MARK: - Token storage

enum AuthStore {
    private static let tokenKey   = "api_access_token"
    private static let userIdKey  = "api_user_id"
    private static let profileIdKey = "api_profile_id"

    static var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }
    static var userId: String? {
        get { UserDefaults.standard.string(forKey: userIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: userIdKey) }
    }
    static var profileId: String? {
        get { UserDefaults.standard.string(forKey: profileIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: profileIdKey) }
    }
    static var isLoggedIn: Bool { token != nil }

    static func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
        UserDefaults.standard.removeObject(forKey: profileIdKey)
    }
}

// MARK: - Response models

struct TokenResponse: Decodable {
    let access_token: String
    let user_id: String
    let email: String
    let name: String?
}

struct BabyProfileResponse: Decodable {
    let id: String
    let name: String
    let birthday_timestamp: Double?
    let gender: String
    let photo_base64: String?
}

struct SleepSessionAPIResponse: Decodable {
    let id: String
    let start: String
    let end: String
}

struct SleepGoalAPIResponse: Decodable {
    let goal_hours: Double
}

struct BabyMemoryAPIResponse: Decodable {
    let id: String
    let title: String
    let date: String
    let text: String
    let category: String
}

struct DoctorVisitAPIResponse: Decodable {
    let id: String
    let doctor_name: String
    let specialty: String
    let clinic: String
    let visit_date: String
    let visit_type: String
    let visit_title: String
    let notes: String
    let weight_kg: Double?
    let height_cm: Double?
    let prescriptions: String   // comma-separated
    let is_completed: Bool
}

struct VisitReminderAPIResponse: Decodable {
    let id: String
    let visit_day_timestamp: Double
    let note: String
    let notify_days_before: String   // comma-separated
    let kind_raw: String
    let hour: Double?
    let minute: Double?
}

struct VaccineRecordAPIResponse: Decodable {
    let id: String
    let name: String
    let full_name: String
    let age_range: String
    let due_date_timestamp: Double?
    let scheduled_timestamp: Double?
    let scheduled_hour: Double?
    let scheduled_minute: Double?
    let completed_timestamp: Double?
    let dose_number: Double?
    let total_doses: Double?
    let doctor_name: String?
    let notes: String
}

struct VaccinationReminderAPIResponse: Decodable {
    let id: String
    let day_timestamp: Double
    let hour: Double
    let minute: Double
    let note: String
    let is_enabled: Bool
    let notify_days_before: String   // comma-separated e.g. "1,3"
}

struct GrowthMeasurementAPIResponse: Decodable {
    let id: String
    let type_raw: String
    let value: Double
    let date: String
    let percentile: Double?
}

struct GrowthComparisonAPIResponse: Decodable {
    let parent1_type: String
    let parent2_type: String
    let parent1_height_cm: Double?
    let parent2_height_cm: Double?
    let baby_height_cm: Double?
    let parent1_skin_tone_index: Int
    let parent2_skin_tone_index: Int
    let baby_skin_tone_index: Int
}

struct DiaperLogAPIResponse: Decodable {
    let id: String
    let type_raw: String
    let note: String?
    let date: String
}

struct FeedingLogAPIResponse: Decodable {
    let id: String
    let type_raw: String
    let volume_text: String?
    let notes_text: String?
    let time_text: String
    let date_text: String
    let saved_at_epoch: Double?
}

// MARK: - API errors

enum APIError: LocalizedError {
    case noToken
    case serverError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .noToken:           return "Not logged in"
        case .serverError(let m): return m
        case .unknown:           return "Unknown error"
        }
    }
}

// MARK: - APIClient

enum APIClient {

    static let baseURL = "https://mybaby-backend-api-production.up.railway.app"

    // MARK: Auth

    static func register(email: String, password: String, name: String,
                         completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        let body: [String: Any] = ["email": email, "password": password, "name": name]
        request(path: "/auth/register", method: "POST", body: body, token: nil, completion: completion)
    }

    static func login(email: String, password: String,
                      completion: @escaping (Result<TokenResponse, Error>) -> Void) {
        let body: [String: Any] = ["email": email, "password": password]
        request(path: "/auth/login", method: "POST", body: body, token: nil, completion: completion)
    }

    // MARK: Profile

    static func getProfiles(completion: @escaping (Result<[BabyProfileResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/profile", method: "GET", body: nil, token: token, completion: completion)
    }

    static func createProfile(name: String, birthday: Double?, gender: String, photoBase64: String?,
                              completion: @escaping (Result<BabyProfileResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        var body: [String: Any] = ["name": name, "gender": gender]
        if let b = birthday { body["birthday_timestamp"] = b }
        if let p = photoBase64 { body["photo_base64"] = p }
        request(path: "/profile", method: "POST", body: body, token: token, completion: completion)
    }

    static func updateProfile(id: String, name: String?, birthday: Double?, gender: String?, photoBase64: String?,
                              completion: @escaping (Result<BabyProfileResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        var body: [String: Any] = [:]
        if let n = name { body["name"] = n }
        if let b = birthday { body["birthday_timestamp"] = b }
        if let g = gender { body["gender"] = g }
        if let p = photoBase64 { body["photo_base64"] = p }
        request(path: "/profile/\(id)", method: "PUT", body: body, token: token, completion: completion)
    }

    // MARK: Sleep

    static func addSleep(session: SleepSession,
                         completion: @escaping (Result<SleepSessionAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        let iso = ISO8601DateFormatter()
        let body: [String: Any] = [
            "id": session.id.uuidString,
            "start": iso.string(from: session.start),
            "end": iso.string(from: session.end)
        ]
        request(path: "/sleep", method: "POST", body: body, token: token, completion: completion)
    }

    static func getSleep(completion: @escaping (Result<[SleepSessionAPIResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/sleep", method: "GET", body: nil, token: token, completion: completion)
    }

    static func setSleepGoal(hours: Double,
                             completion: @escaping (Result<SleepGoalAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        let body: [String: Any] = ["goal_hours": hours]
        request(path: "/sleep/goal", method: "POST", body: body, token: token, completion: completion)
    }

    static func getSleepGoal(completion: @escaping (Result<SleepGoalAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/sleep/goal", method: "GET", body: nil, token: token, completion: completion)
    }

    // MARK: Baby Memories

    static func addMemory(_ m: BabyMemory,
                          completion: @escaping (Result<BabyMemoryAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        let iso = ISO8601DateFormatter()
        let body: [String: Any] = [
            "id": m.id.uuidString,
            "title": m.title,
            "date": iso.string(from: m.date),
            "text": m.text,
            "category": m.category.rawValue
        ]
        request(path: "/memory", method: "POST", body: body, token: token, completion: completion)
    }

    static func getMemories(completion: @escaping (Result<[BabyMemoryAPIResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/memory", method: "GET", body: nil, token: token, completion: completion)
    }

    static func deleteMemory(id: UUID, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        requestRaw(path: "/memory/\(id.uuidString)", method: "DELETE", token: token, completion: completion)
    }

    // MARK: Doctor Visits

    static func upsertDoctorVisit(_ v: DoctorVisit,
                                  completion: @escaping (Result<DoctorVisitAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        let iso = ISO8601DateFormatter()
        var body: [String: Any] = [
            "id": v.id.uuidString,
            "doctor_name": v.doctorName,
            "specialty": v.specialty,
            "clinic": v.clinic,
            "visit_date": iso.string(from: v.visitDate),
            "visit_type": v.visitType,
            "visit_title": v.visitTitle,
            "notes": v.notes,
            "prescriptions": v.prescriptions.joined(separator: ","),
            "is_completed": v.isCompleted
        ]
        if let w = v.weightKg  { body["weight_kg"]  = w }
        if let h = v.heightCm  { body["height_cm"]  = h }
        request(path: "/doctor-visit/visit", method: "POST", body: body, token: token, completion: completion)
    }

    static func getDoctorVisits(completion: @escaping (Result<[DoctorVisitAPIResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/doctor-visit/visits", method: "GET", body: nil, token: token, completion: completion)
    }

    static func deleteDoctorVisit(id: UUID, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        requestRaw(path: "/doctor-visit/visit/\(id.uuidString)", method: "DELETE", token: token, completion: completion)
    }

    static func upsertVisitReminder(_ r: VisitReminder,
                                    completion: @escaping (Result<VisitReminderAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        let daysStr = r.notifyDaysBefore.map { String($0) }.joined(separator: ",")
        var body: [String: Any] = [
            "id": r.id.uuidString,
            "visit_day_timestamp": r.visitDayTimestamp,
            "note": r.note,
            "notify_days_before": daysStr,
            "kind_raw": r.kindRaw
        ]
        if let h = r.hour   { body["hour"]   = h }
        if let m = r.minute { body["minute"] = m }
        request(path: "/doctor-visit/reminder", method: "POST", body: body, token: token, completion: completion)
    }

    static func getVisitReminders(completion: @escaping (Result<[VisitReminderAPIResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/doctor-visit/reminders", method: "GET", body: nil, token: token, completion: completion)
    }

    static func deleteVisitReminder(id: UUID, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        requestRaw(path: "/doctor-visit/reminder/\(id.uuidString)", method: "DELETE", token: token, completion: completion)
    }

    // MARK: Vaccination

    static func upsertVaccine(_ v: Vaccine,
                              completion: @escaping (Result<VaccineRecordAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        var body: [String: Any] = [
            "id": v.id.uuidString,
            "name": v.name,
            "full_name": v.fullName,
            "age_range": v.ageRange,
            "notes": v.notes
        ]
        if let t = v.dueDateTimestamp      { body["due_date_timestamp"]  = t }
        if let t = v.scheduledTimestamp    { body["scheduled_timestamp"] = t }
        if let h = v.scheduledHour         { body["scheduled_hour"]      = h }
        if let m = v.scheduledMinute       { body["scheduled_minute"]    = m }
        if let t = v.completedTimestamp    { body["completed_timestamp"] = t }
        if let n = v.doseNumber            { body["dose_number"]         = n }
        if let n = v.totalDoses            { body["total_doses"]         = n }
        if let d = v.doctorName            { body["doctor_name"]         = d }
        request(path: "/vaccination/vaccine", method: "POST", body: body, token: token, completion: completion)
    }

    static func getVaccines(completion: @escaping (Result<[VaccineRecordAPIResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/vaccination/vaccines", method: "GET", body: nil, token: token, completion: completion)
    }

    static func deleteVaccine(id: UUID, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        requestRaw(path: "/vaccination/vaccine/\(id.uuidString)", method: "DELETE", token: token, completion: completion)
    }

    static func upsertReminder(_ r: VaccinationReminder,
                               completion: @escaping (Result<VaccinationReminderAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        let daysStr = r.notifyDaysBefore.map { String($0) }.joined(separator: ",")
        let body: [String: Any] = [
            "id": r.id.uuidString,
            "day_timestamp": r.dayTimestamp,
            "hour": r.hour,
            "minute": r.minute,
            "note": r.note,
            "is_enabled": r.isEnabled,
            "notify_days_before": daysStr
        ]
        request(path: "/vaccination/reminder", method: "POST", body: body, token: token, completion: completion)
    }

    static func getReminders(completion: @escaping (Result<[VaccinationReminderAPIResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/vaccination/reminders", method: "GET", body: nil, token: token, completion: completion)
    }

    static func deleteReminder(id: UUID, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        requestRaw(path: "/vaccination/reminder/\(id.uuidString)", method: "DELETE", token: token, completion: completion)
    }

    // MARK: Growth

    static func addGrowthMeasurement(_ m: GrowthMeasurement,
                                     completion: @escaping (Result<GrowthMeasurementAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        let iso = ISO8601DateFormatter()
        var body: [String: Any] = [
            "id": m.id.uuidString,
            "type_raw": m.typeRaw,
            "value": m.value,
            "date": iso.string(from: m.date)
        ]
        if let p = m.percentile { body["percentile"] = Double(p) }
        request(path: "/growth/measurement", method: "POST", body: body, token: token, completion: completion)
    }

    static func getGrowthMeasurements(completion: @escaping (Result<[GrowthMeasurementAPIResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/growth/measurements", method: "GET", body: nil, token: token, completion: completion)
    }

    static func setGrowthComparison(_ data: GrowthComparisonData,
                                    completion: @escaping (Result<GrowthComparisonAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        var body: [String: Any] = [
            "parent1_type": data.parent1Type.rawValue,
            "parent2_type": data.parent2Type.rawValue,
            "parent1_skin_tone_index": data.parent1SkinToneIndex,
            "parent2_skin_tone_index": data.parent2SkinToneIndex,
            "baby_skin_tone_index": data.babySkinToneIndex
        ]
        if let h = data.parent1HeightCm { body["parent1_height_cm"] = h }
        if let h = data.parent2HeightCm { body["parent2_height_cm"] = h }
        if let h = data.babyHeightCm    { body["baby_height_cm"] = h }
        request(path: "/growth/comparison", method: "POST", body: body, token: token, completion: completion)
    }

    static func getGrowthComparison(completion: @escaping (Result<GrowthComparisonAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/growth/comparison", method: "GET", body: nil, token: token, completion: completion)
    }

    // MARK: Diaper

    static func addDiaper(id: UUID, typeRaw: String, note: String?, date: Date,
                          completion: @escaping (Result<DiaperLogAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        let iso = ISO8601DateFormatter()
        var body: [String: Any] = [
            "id": id.uuidString,
            "type_raw": typeRaw,
            "date": iso.string(from: date)
        ]
        if let n = note { body["note"] = n }
        request(path: "/diaper", method: "POST", body: body, token: token, completion: completion)
    }

    static func getDiapers(completion: @escaping (Result<[DiaperLogAPIResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/diaper", method: "GET", body: nil, token: token, completion: completion)
    }

    // MARK: Feeding

    static func addFeeding(entry: FeedingLogEntry,
                           completion: @escaping (Result<FeedingLogAPIResponse, Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        var body: [String: Any] = [
            "id": entry.id.uuidString,
            "type_raw": entry.typeRaw,
            "time_text": entry.timeText,
            "date_text": entry.dateText
        ]
        if let v = entry.volumeText { body["volume_text"] = v }
        if let n = entry.notesText { body["notes_text"] = n }
        if let e = entry.savedAtEpochSeconds { body["saved_at_epoch"] = e }
        request(path: "/feeding", method: "POST", body: body, token: token, completion: completion)
    }

    static func getFeedings(completion: @escaping (Result<[FeedingLogAPIResponse], Error>) -> Void) {
        guard let token = AuthStore.token else { completion(.failure(APIError.noToken)); return }
        request(path: "/feeding", method: "GET", body: nil, token: token, completion: completion)
    }

    // MARK: - Private

    static func requestRaw(path: String, method: String, token: String,
                           completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: baseURL + path) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(error)); return }
                completion(.success(data ?? Data()))
            }
        }.resume()
    }

    private static func request<T: Decodable>(path: String, method: String,
                                              body: [String: Any]?, token: String?,
                                              completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: baseURL + path) else { return }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        if let body { req.httpBody = try? JSONSerialization.data(withJSONObject: body) }

        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(error)); return }
                guard let data else { completion(.failure(APIError.unknown)); return }
                if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                    let msg = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["detail"] as? String ?? "Server error"
                    completion(.failure(APIError.serverError(msg))); return
                }
                do {
                    let decoded = try JSONDecoder().decode(T.self, from: data)
                    completion(.success(decoded))
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
