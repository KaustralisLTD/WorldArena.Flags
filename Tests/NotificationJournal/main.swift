import Foundation

let suite = "NotificationJournalMigrationTests." + UUID().uuidString
let defaults = UserDefaults(suiteName: suite)!
defer { defaults.removePersistentDomain(forName: suite) }
let key = "notifications.inapp.log.v1"
func data(_ rows: [[String: Any]]) -> Data { try! JSONSerialization.data(withJSONObject: rows) }
func row(_ id: String) -> [String: Any] {
    ["id": id, "title": "Событие", "body": "История", "date": 12345.0, "source": "duel"]
}
let original = data([row("old"), row("duel_challenge_match"), row("existing"), row("old")])
defaults.set(original, forKey: key)
defaults.set(data([row("existing")]), forKey: key + ".alice")
LegacyNotificationJournalMigration.migrate(defaults: defaults, username: nil)
assert(defaults.string(forKey: key + ".migrationOwner.v2") == nil)
LegacyNotificationJournalMigration.migrate(defaults: defaults, username: "alice")
let migrated = defaults.data(forKey: key + ".alice")!
let rows = try! JSONSerialization.jsonObject(with: migrated) as! [[String: Any]]
assert(rows.count == 3)
assert(rows.first { $0["id"] as? String == "old" }?["body"] as? String == "История")
let read = Set(defaults.stringArray(forKey: "notifications.inbox.v2.alice.read")!)
assert(read.contains("old") && read.contains("duel_challenge:match"))
assert(!read.contains("existing")) // Existing unread events stay unread.
assert(defaults.data(forKey: key) == original)
LegacyNotificationJournalMigration.migrate(defaults: defaults, username: "alice")
assert(defaults.data(forKey: key + ".alice") == migrated)
LegacyNotificationJournalMigration.migrate(defaults: defaults, username: "bob")
assert(defaults.data(forKey: key + ".bob") == nil)
// A corrupt destination must not be overwritten or consume the migration.
defaults.removeObject(forKey: key + ".migrationOwner.v2")
defaults.set(Data("corrupt".utf8), forKey: key + ".bob")
LegacyNotificationJournalMigration.migrate(defaults: defaults, username: "bob")
assert(defaults.data(forKey: key + ".bob") == Data("corrupt".utf8))
assert(defaults.string(forKey: key + ".migrationOwner.v2") == nil)
print("Notification journal migration: all checks passed")
