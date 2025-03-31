import WidgetKit
import SwiftUI

// Simple model for a chore to be used in the widget
struct WidgetChore: Identifiable, Codable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var categoryName: String?
    var categoryColor: String?
    var dueDate: Date?
    
    static var mockChores: [WidgetChore] {
        [
            WidgetChore(id: UUID(), title: "Clean kitchen", isCompleted: false, categoryName: "Kitchen", categoryColor: "blue", dueDate: Date().addingTimeInterval(3600)),
            WidgetChore(id: UUID(), title: "Vacuum living room", isCompleted: false, categoryName: "Living Room", categoryColor: "orange", dueDate: Date().addingTimeInterval(7200)),
            WidgetChore(id: UUID(), title: "Do laundry", isCompleted: false, categoryName: "Bedroom", categoryColor: "purple", dueDate: Date().addingTimeInterval(10800)),
            WidgetChore(id: UUID(), title: "Take out trash", isCompleted: false, categoryName: "Other", categoryColor: "gray", dueDate: Date().addingTimeInterval(14400)),
            WidgetChore(id: UUID(), title: "Mop bathroom floor", isCompleted: false, categoryName: "Bathroom", categoryColor: "green", dueDate: Date().addingTimeInterval(18000)),
            WidgetChore(id: UUID(), title: "Clean windows", isCompleted: false, categoryName: "Kitchen", categoryColor: "blue", dueDate: Date().addingTimeInterval(21600))
        ]
    }
}

struct ChoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> ChoreEntry {
        ChoreEntry(date: Date(), chores: WidgetChore.mockChores)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChoreEntry) -> ()) {
        let entry = ChoreEntry(date: Date(), chores: loadChores())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [ChoreEntry] = []
        let currentDate = Date()
        let chores = loadChores()
        
        // First entry should be current date/time
        let initialEntry = ChoreEntry(date: currentDate, chores: chores)
        entries.append(initialEntry)
        
        // Create additional entries every 15 minutes for the next hour
        for minuteOffset in stride(from: 15, to: 75, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = ChoreEntry(date: entryDate, chores: chores)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!))
        completion(timeline)
    }
    
    private func loadChores() -> [WidgetChore] {
        // Try to get chores from UserDefaults (shared with main app)
        if let savedChores = UserDefaults.standard.data(forKey: "widgetChores") {
            do {
                if let choresDicts = try JSONSerialization.jsonObject(with: savedChores) as? [[String: Any]] {
                    var chores: [WidgetChore] = []
                    
                    for dict in choresDicts {
                        if let idString = dict["id"] as? String,
                           let id = UUID(uuidString: idString),
                           let title = dict["title"] as? String,
                           let isCompleted = dict["isCompleted"] as? Bool {
                            
                            let categoryName = dict["categoryName"] as? String
                            let categoryColor = dict["categoryColor"] as? String
                            let dueDate = dict["dueDate"] as? Date
                            
                            let chore = WidgetChore(
                                id: id,
                                title: title,
                                isCompleted: isCompleted,
                                categoryName: categoryName,
                                categoryColor: categoryColor,
                                dueDate: dueDate
                            )
                            
                            chores.append(chore)
                        }
                    }
                    
                    // Filter to only show incomplete chores
                    return chores.filter { !$0.isCompleted }.prefix(6).map { $0 }
                }
            } catch {
                print("Failed to decode widget chores: \(error.localizedDescription)")
            }
        }
        
        // Try to load original chores as a fallback
        if let savedChores = UserDefaults.standard.data(forKey: "savedChores") {
            do {
                let chores = try JSONDecoder().decode([WidgetChore].self, from: savedChores)
                return chores.filter { !$0.isCompleted }.prefix(6).map { $0 }
            } catch {
                print("Failed to decode chores: \(error.localizedDescription)")
            }
        }
        
        // Return mock chores if unable to load from UserDefaults
        return WidgetChore.mockChores
    }
}

struct ChoreEntry: TimelineEntry {
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
                    if let categoryColor = firstChore.categoryColor {
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
                    Text(timeRemaining(for: dueDate))
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
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
            
            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
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
                } else {
                    return "Due in \(minute)m"
                }
            }
        }
        return date.formatted(date: .abbreviated, time: .shortened)
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
                
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
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
                        if let categoryColor = chore.categoryColor {
                            Circle()
                                .fill(Color(categoryColor))
                                .frame(width: 10, height: 10)
                        }
                        
                        Text(chore.title)
                            .lineLimit(1)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Spacer()
                        
                        if let dueDate = chore.dueDate, Calendar.current.isDateInToday(dueDate) {
                            Text(dueDate.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
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
}

struct HTasksWidget: Widget {
    let kind: String = "HTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChoreProvider()) { entry in
            ChoreWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("HTasks Chores")
        .description("See your upcoming chores at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct HTasksWidget_Previews: PreviewProvider {
    static var previews: some View {
        ChoreWidgetEntryView(entry: ChoreEntry(date: Date(), chores: WidgetChore.mockChores))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        ChoreWidgetEntryView(entry: ChoreEntry(date: Date(), chores: WidgetChore.mockChores))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}

