import WidgetKit
import SwiftUI

// Simple model for a chore to be used in the widget
struct WidgetChore: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var categoryId: UUID?
    var categoryName: String?
    var categoryColor: String?
    var dueDate: Date?
    var createdDate: Date
    
    static var mockChores: [WidgetChore] {
        [
            WidgetChore(
                id: UUID(),
                title: "Clean kitchen",
                isCompleted: false,
                categoryId: UUID(),
                categoryName: "Home",
                categoryColor: "blue",
                dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
                createdDate: Date()
            ),
            WidgetChore(
                id: UUID(),
                title: "Buy groceries",
                isCompleted: false,
                categoryId: UUID(),
                categoryName: "Shopping",
                categoryColor: "green",
                dueDate: nil,
                createdDate: Date()
            ),
            WidgetChore(
                id: UUID(),
                title: "Review project",
                isCompleted: false,
                categoryId: nil,
                categoryName: nil,
                categoryColor: nil,
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
                createdDate: Date()
            )
        ]
    }
}

struct ChoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChoreEntry {
        ChoreEntry(date: Date(), chores: WidgetChore.mockChores)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChoreEntry) -> ()) {
        let chores = loadChores()
        let entry = ChoreEntry(date: Date(), chores: chores)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChoreEntry>) -> ()) {
        let entries: [ChoreEntry] = [
            ChoreEntry(date: Date(), chores: loadChores())
        ]
        
        // Create a timeline that updates every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
    
    func loadChores() -> [WidgetChore] {
        // Try to access the shared container
        guard let userDefaults = UserDefaults(suiteName: "group.com.yourdomain.HTasks") else {
            print("Could not access shared UserDefaults")
            return WidgetChore.mockChores
        }
        
        guard let data = userDefaults.data(forKey: "widgetChores") else {
            print("No chores data found in shared UserDefaults")
            return WidgetChore.mockChores
        }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            guard let choresDicts = jsonObject as? [[String: Any]] else {
                print("Failed to cast JSON to dictionary array")
                return WidgetChore.mockChores
            }
            
            let chores = choresDicts.compactMap { dict -> WidgetChore? in
                guard let idString = dict["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = dict["title"] as? String else {
                    return nil
                }
                
                let isCompleted = dict["isCompleted"] as? Bool ?? false
                let categoryIdString = dict["categoryId"] as? String
                let categoryId = categoryIdString.flatMap { UUID(uuidString: $0) }
                let categoryName = dict["categoryName"] as? String
                let categoryColor = dict["categoryColor"] as? String
                
                // Handle date conversion
                var dueDate: Date?
                if let dueDateDict = dict["dueDate"] as? [String: Any],
                   let timestamp = dueDateDict["timestamp"] as? TimeInterval {
                    dueDate = Date(timeIntervalSince1970: timestamp)
                }
                
                var createdDate = Date()
                if let createdDateDict = dict["createdDate"] as? [String: Any],
                   let timestamp = createdDateDict["timestamp"] as? TimeInterval {
                    createdDate = Date(timeIntervalSince1970: timestamp)
                }
                
                return WidgetChore(
                    id: id,
                    title: title,
                    isCompleted: isCompleted,
                    categoryId: categoryId,
                    categoryName: categoryName,
                    categoryColor: categoryColor,
                    dueDate: dueDate,
                    createdDate: createdDate
                )
            }
            
            // Filter and sort chores
            let filteredChores = chores.filter { !$0.isCompleted }
                .sorted { (chore1, chore2) in
                    if let date1 = chore1.dueDate, let date2 = chore2.dueDate {
                        return date1 < date2
                    } else if chore1.dueDate != nil {
                        return true
                    } else if chore2.dueDate != nil {
                        return false
                    } else {
                        return chore1.title < chore2.title
                    }
                }
            
            // Return up to 10 chores
            return Array(filteredChores.prefix(10))
        } catch {
            print("Failed to decode widget chores: \(error)")
            return WidgetChore.mockChores
        }
    }
}

struct ChoreEntry: TimelineEntry, Identifiable {
    var id: UUID = UUID()
    let date: Date
    let chores: [WidgetChore]
}

struct ChoreWidgetEntryView : View {
    var entry: ChoreProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallChoreView(entry: entry)
        case .systemMedium:
            MediumChoreView(entry: entry)
        case .systemLarge:
            LargeChoreView(entry: entry)
        default:
            SmallChoreView(entry: entry)
        }
    }
}

struct SmallChoreView: View {
    var entry: ChoreProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Chore")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
            
            if let firstChore = entry.chores.first {
                HStack {
                    if let categoryColor = firstChore.categoryColor, !categoryColor.isEmpty {
                        Circle()
                            .fill(Color(categoryColor))
                            .frame(width: 12, height: 12)
                    }
                    
                    Text(firstChore.title)
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                        .lineLimit(1)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                
                if let dueDate = firstChore.dueDate {
                    if #available(iOS 15.0, *) {
                        Text(timeRemaining(for: dueDate))
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                    } else {
                        // Fallback for older iOS versions
                        Text(formatDate(dueDate))
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                    }
                }
            } else {
                Text("All done!")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text("No pending chores")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
            }
            
            Spacer()
            
            if #available(iOS 15.0, *) {
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
            } else {
                // Fallback for older iOS versions
                Text(formatDate(entry.date))
                    .font(.caption2)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                                  [Color.black, Color.blue.opacity(0.5)] : 
                                  [Color.white, Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    func timeRemaining(for date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            let components = calendar.dateComponents([.hour, .minute], from: now, to: date)
            if let hour = components.hour, let minute = components.minute {
                if hour > 0 {
                    return "Due in \(hour)h \(minute)m"
                } else if minute > 0 {
                    return "Due in \(minute)m"
                } else {
                    return "Due now"
                }
            }
        }
        
        // For iOS 15+, we'd use date.formatted()
        return formatDate(date)
    }
    
    // Helper for iOS 14 compatibility
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct MediumChoreView: View {
    var entry: ChoreProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Chores")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                
                Spacer()
                
                if #available(iOS 15.0, *) {
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                } else {
                    // Fallback for older iOS versions
                    Text(formatDate(entry.date))
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                }
            }
            
            if entry.chores.isEmpty {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("All done!")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical)
            } else {
                // Display up to 6 chores
                ForEach(entry.chores.prefix(6)) { chore in
                    HStack {
                        if let categoryColor = chore.categoryColor, !categoryColor.isEmpty {
                            Circle()
                                .fill(Color(categoryColor))
                                .frame(width: 10, height: 10)
                        }
                        
                        Text(chore.title)
                            .lineLimit(1)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Spacer()
                        
                        if let dueDate = chore.dueDate, Calendar.current.isDateInToday(dueDate) {
                            if #available(iOS 15.0, *) {
                                Text(dueDate.formatted(date: .omitted, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                            } else {
                                // Fallback for older iOS versions
                                Text(formatTimeOnly(dueDate))
                                    .font(.caption)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                                  [Color.black, Color.blue.opacity(0.5)] : 
                                  [Color.white, Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // Helper for iOS 14 compatibility
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper to format just the time
    func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct LargeChoreView: View {
    var entry: ChoreProvider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("HTasks")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                if #available(iOS 15.0, *) {
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                } else {
                    // Fallback for older iOS versions
                    Text(formatDate(entry.date))
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                }
            }
            
            Text("Today's Pending Chores")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                .padding(.top, 2)
            
            if entry.chores.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.green)
                    
                    Text("All done!")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("No pending chores")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 30)
            } else {
                // Display all chores, we can fit more in the large widget
                ForEach(entry.chores) { chore in
                    HStack(spacing: 10) {
                        if let categoryColor = chore.categoryColor, !categoryColor.isEmpty {
                            Circle()
                                .fill(Color(categoryColor))
                                .frame(width: 12, height: 12)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(chore.title)
                                .font(.system(.body, design: .rounded))
                                .lineLimit(1)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            if let categoryName = chore.categoryName, !categoryName.isEmpty {
                                Text(categoryName)
                                    .font(.caption)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                            }
                        }
                        
                        Spacer()
                        
                        if let dueDate = chore.dueDate {
                            Text(timeRemaining(for: dueDate))
                                .font(.caption)
                                .foregroundColor(isDueDateSoon(dueDate) ? .red : (colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6)))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                                  [Color.black, Color.blue.opacity(0.5)] : 
                                  [Color.white, Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    func isDueDateSoon(_ date: Date) -> Bool {
        let timeInterval = date.timeIntervalSinceNow
        // Return true if the due date is within the next 24 hours
        return timeInterval >= 0 && timeInterval <= 86400 // 24 hours in seconds
    }
    
    func timeRemaining(for date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            if #available(iOS 15.0, *) {
                return "Today, " + date.formatted(date: .omitted, time: .shortened)
            } else {
                return "Today, " + formatTimeOnly(date)
            }
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            if #available(iOS 15.0, *) {
                return date.formatted(date: .abbreviated, time: .omitted)
            } else {
                return formatDateOnly(date)
            }
        }
    }
    
    // Helper for iOS 14 compatibility
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper to format just the time
    func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper to format just the date
    func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct HTasksWidget: Widget {
    let kind: String = "HTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChoreProvider()) { entry in
            ChoreWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("HTasks Chores")
        .description("See your upcoming chores at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HTasksWidget_Previews: PreviewProvider {
    static var previews: some View {
        ChoreWidgetEntryView(entry: ChoreEntry(date: Date(), chores: WidgetChore.mockChores))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        ChoreWidgetEntryView(entry: ChoreEntry(date: Date(), chores: WidgetChore.mockChores))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        
        ChoreWidgetEntryView(entry: ChoreEntry(date: Date(), chores: WidgetChore.mockChores))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}



