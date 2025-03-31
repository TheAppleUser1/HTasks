import WidgetKit
import SwiftUI

struct SimpleProvider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleTimeEntry {
        SimpleTimeEntry(date: Date(), emoji: "⏰")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleTimeEntry) -> ()) {
        let entry = SimpleTimeEntry(date: Date(), emoji: getRandomEmoji(for: Date()))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleTimeEntry] = []
        let currentDate = Date()
        
        // First entry should be current date/time
        let initialEntry = SimpleTimeEntry(date: currentDate, emoji: getRandomEmoji(for: currentDate))
        entries.append(initialEntry)
        
        // Create additional entries every 5 minutes for the next hour
        for minuteOffset in stride(from: 5, to: 65, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let emoji = getRandomEmoji(for: entryDate)
            let entry = SimpleTimeEntry(date: entryDate, emoji: emoji)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!))
        completion(timeline)
    }
    
    func getRandomEmoji(for date: Date) -> String {
        let emojis = ["😊", "🥳", "🚀", "🔥", "✨", "💫", "🌈", "🦄", "🎉", "❤️", "🌟", "💪"]
        let minute = Calendar.current.component(.minute, from: date)
        let second = Calendar.current.component(.second, from: date)
        let index = (minute + second) % emojis.count
        return emojis[index]
    }
}

struct SimpleTimeEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct SimpleWidgetEntryView : View {
    var entry: SimpleProvider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                                  [Color.black, Color.blue.opacity(0.5)] : 
                                  [Color.white, Color.blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 10) {
                // Emoji
                Text(entry.emoji)
                    .font(.system(size: 60))
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                
                // Time
                Text(entry.date, style: .time)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.5), radius: 1, x: 0, y: 1)
                
                // Date
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
            }
            .padding()
        }
    }
}

struct SimpleTimeWidget: Widget {
    let kind: String = "SimpleTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SimpleProvider()) { entry in
            SimpleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Time & Emoji")
        .description("Display the current time with your favorite emoji.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct SimpleWidget_Previews: PreviewProvider {
    static var previews: some View {
        SimpleWidgetEntryView(entry: SimpleTimeEntry(date: Date(), emoji: "😊"))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
} 