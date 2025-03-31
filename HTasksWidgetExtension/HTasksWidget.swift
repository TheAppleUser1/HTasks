import WidgetKit
import SwiftUI
import CoreData

struct Provider: TimelineProvider {
    let coreDataManager = CoreDataManager.shared
    
    func placeholder(in context: Context) -> ChoreEntry {
        ChoreEntry(date: Date(), chores: [], streak: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ChoreEntry) -> ()) {
        let entry = ChoreEntry(
            date: Date(),
            chores: Array(coreDataManager.fetchChores().prefix(6)),
            streak: coreDataManager.getOrCreateStreak()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [ChoreEntry] = []
        let currentDate = Date()
        
        // Create a timeline with an entry every hour
        for hourOffset in 0 ..< 24 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = ChoreEntry(
                date: entryDate,
                chores: Array(coreDataManager.fetchChores().prefix(6)),
                streak: coreDataManager.getOrCreateStreak()
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct ChoreEntry: TimelineEntry {
    let date: Date
    let chores: [ChoreEntity]
    let streak: StreakEntity?
}

struct HTasksWidgetsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            Text("Unsupported widget size")
        }
    }
}

struct SmallWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient matching app style
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                                  [Color.black, Color.blue.opacity(0.2)] : 
                                  [Color.white, Color.blue.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Chore")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                
                if let firstChore = entry.chores.first {
                    HStack {
                        if let category = firstChore.category {
                            Circle()
                                .fill(Color(category.color ?? "blue"))
                                .frame(width: 12, height: 12)
                        }
                        
                        Text(firstChore.title ?? "No chore")
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
                
                if let streak = entry.streak, streak.currentStreak > 0 {
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(streak.currentStreak) day streak")
                            .font(.caption2)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    }
                }
            }
            .padding()
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

struct MediumWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient matching app style
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                                  [Color.black, Color.blue.opacity(0.2)] : 
                                  [Color.white, Color.blue.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Chores")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    
                    Spacer()
                    
                    if let streak = entry.streak, streak.currentStreak > 0 {
                        HStack {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                            Text("\(streak.currentStreak)")
                                .fontWeight(.bold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
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
                    ForEach(entry.chores.prefix(6), id: \.id) { chore in
                        HStack {
                            if let category = chore.category {
                                Circle()
                                    .fill(Color(category.color ?? "blue"))
                                    .frame(width: 10, height: 10)
                            }
                            
                            Text(chore.title ?? "")
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
                
                if entry.chores.count < 6 {
                    Text("+ Add Chore")
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                        )
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct LargeWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient matching app style
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                                  [Color.black, Color.blue.opacity(0.2)] : 
                                  [Color.white, Color.blue.opacity(0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 16) {
                // Top section with stats
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("HTasks")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        if let streak = entry.streak {
                            HStack(alignment: .bottom, spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundColor(.orange)
                                Text("\(streak.currentStreak)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                Text("day streak")
                                    .font(.caption)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                    .padding(.bottom, 4)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Completed count in circular progress
                    VStack {
                        let completedCount = entry.streak?.totalCompletions ?? 0
                        Text("\(completedCount)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("completed")
                            .font(.caption2)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    }
                    .padding(12)
                    .background(
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                    )
                }
                .padding(.horizontal)
                
                // Motivational message
                Text(motivationalMessage(streak: entry.streak?.currentStreak ?? 0))
                    .italic()
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    .padding(.horizontal)
                
                Divider()
                    .background(colorScheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.1))
                
                // Chores list
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Chores")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    
                    if entry.chores.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.green)
                                
                                Text("All done!")
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            Spacer()
                        }
                        .padding()
                    } else {
                        // Group chores by category
                        let groupedChores = Dictionary(grouping: entry.chores) { chore -> String in
                            chore.category?.name ?? "Uncategorized"
                        }
                        
                        ForEach(groupedChores.keys.sorted(), id: \.self) { category in
                            if let chores = groupedChores[category] {
                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
                                
                                ForEach(chores, id: \.id) { chore in
                                    HStack {
                                        if let category = chore.category {
                                            Circle()
                                                .fill(Color(category.color ?? "blue"))
                                                .frame(width: 8, height: 8)
                                        }
                                        
                                        Text(chore.title ?? "")
                                            .lineLimit(1)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
                                        Spacer()
                                        
                                        // Priority indicator
                                        if chore.priority > 0 {
                                            Image(systemName: chore.priority > 1 ? "exclamationmark.2" : "exclamationmark")
                                                .foregroundColor(.red.opacity(0.8))
                                                .font(.caption2)
                                        }
                                        
                                        if let dueDate = chore.dueDate {
                                            Text(dueDate.formatted(date: .omitted, time: .shortened))
                                                .font(.caption)
                                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                                        }
                                    }
                                    .padding(.leading, 4)
                                    .padding(.vertical, 2)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Bottom action bar
                HStack {
                    Spacer()
                    
                    Button(action: {}) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("Add Chore")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
    
    func motivationalMessage(streak: Int32) -> String {
        if streak == 0 {
            return "Start your streak today!"
        } else if streak < 3 {
            return "Keep going! You're building momentum."
        } else if streak < 7 {
            return "Great job on your \(streak)-day streak!"
        } else if streak < 14 {
            return "Impressive! \(streak) days and counting!"
        } else {
            return "Amazing! \(streak)-day streak - you're unstoppable!"
        }
    }
}

struct HTasksWidgets: Widget {
    let kind: String = "HTasksWidgets"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HTasksWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("HTasks")
        .description("Keep track of your chores and streaks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct HTasksWidgets_Previews: PreviewProvider {
    static var previews: some View {
        let previewChores = [
            createPreviewChore(title: "Clean kitchen", categoryName: "Kitchen", color: "blue"),
            createPreviewChore(title: "Vacuum living room", categoryName: "Living Room", color: "orange"),
            createPreviewChore(title: "Laundry", categoryName: "Bedroom", color: "purple"),
            createPreviewChore(title: "Take out trash", categoryName: "Other", color: "gray"),
            createPreviewChore(title: "Mop bathroom floor", categoryName: "Bathroom", color: "green")
        ]
        
        let streak = createPreviewStreak()
        
        Group {
            HTasksWidgetsEntryView(entry: ChoreEntry(date: Date(), chores: previewChores, streak: streak))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            HTasksWidgetsEntryView(entry: ChoreEntry(date: Date(), chores: previewChores, streak: streak))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            HTasksWidgetsEntryView(entry: ChoreEntry(date: Date(), chores: previewChores, streak: streak))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
    
    static func createPreviewChore(title: String, categoryName: String, color: String) -> ChoreEntity {
        let context = CoreDataManager.shared.viewContext
        let chore = ChoreEntity(context: context)
        chore.id = UUID()
        chore.title = title
        chore.dueDate = Date().addingTimeInterval(Double.random(in: 3600...86400))
        chore.isCompleted = false
        chore.priority = Int16.random(in: 0...2)
        
        let category = CategoryEntity(context: context)
        category.id = UUID()
        category.name = categoryName
        category.color = color
        
        chore.category = category
        
        return chore
    }
    
    static func createPreviewStreak() -> StreakEntity {
        let context = CoreDataManager.shared.viewContext
        let streak = StreakEntity(context: context)
        streak.id = UUID()
        streak.currentStreak = 5
        streak.longestStreak = 10
        streak.totalCompletions = 25
        streak.lastCompletedDate = Date()
        streak.startDate = Date().addingTimeInterval(-86400 * 5)
        
        return streak
    }
} 