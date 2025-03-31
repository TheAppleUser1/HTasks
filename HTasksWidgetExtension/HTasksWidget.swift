import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TimeEmojiEntry {
        TimeEmojiEntry(date: Date(), emoji: "⏰")
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeEmojiEntry) -> ()) {
        let entry = TimeEmojiEntry(date: Date(), emoji: getRandomEmoji(for: Date()))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [TimeEmojiEntry] = []
        let currentDate = Date()
        
        // First entry should be current date/time
        let initialEntry = TimeEmojiEntry(date: currentDate, emoji: getRandomEmoji(for: currentDate))
        entries.append(initialEntry)
        
        // Create additional entries every 5 minutes for the next hour
        for minuteOffset in stride(from: 5, to: 65, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let emoji = getRandomEmoji(for: entryDate)
            let entry = TimeEmojiEntry(date: entryDate, emoji: emoji)
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

struct TimeEmojiEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct TimeEmojiWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallTimeEmojiView(entry: entry)
        case .systemMedium:
            MediumTimeEmojiView(entry: entry)
        case .systemLarge:
            LargeTimeEmojiView(entry: entry)
        default:
            Text("Unsupported widget size")
        }
    }
}

struct SmallTimeEmojiView: View {
    var entry: Provider.Entry
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

struct MediumTimeEmojiView: View {
    var entry: Provider.Entry
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
            
            HStack(spacing: 30) {
                // Emoji
                Text(entry.emoji)
                    .font(.system(size: 80))
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 8) {
                    // Time
                    Text(entry.date, style: .time)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.5), radius: 1, x: 0, y: 1)
                    
                    // Date
                    Text(entry.date, style: .date)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
                    
                    Text("Updated just now")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

struct LargeTimeEmojiView: View {
    var entry: Provider.Entry
    @Environment(\.colorScheme) var colorScheme
    
    private let additionalEmojis = ["🌟", "⭐️", "💫", "✨", "🔥", "💕", "🎈"]
    
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
            
            VStack(spacing: 25) {
                // Title
                Text("Time & Emoji")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.5), radius: 1, x: 0, y: 1)
                
                // Main emoji
                Text(entry.emoji)
                    .font(.system(size: 120))
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                
                // Current time
                VStack {
                    Text(entry.date, style: .time)
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .shadow(color: colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.5), radius: 1, x: 0, y: 1)
                    
                    Text(entry.date, style: .date)
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
                }
                
                // Additional emojis in a row
                HStack(spacing: 15) {
                    ForEach(additionalEmojis.prefix(5), id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 30))
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(.top, 30)
            .padding(.horizontal)
        }
    }
}

struct TimeEmojiWidget: Widget {
    let kind: String = "TimeEmojiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TimeEmojiWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Time & Emoji")
        .description("Display the current time with your favorite emoji.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct HTasksWidgets_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimeEmojiWidgetEntryView(entry: TimeEmojiEntry(date: Date(), emoji: "😊"))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            TimeEmojiWidgetEntryView(entry: TimeEmojiEntry(date: Date(), emoji: "🔥"))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
            
            TimeEmojiWidgetEntryView(entry: TimeEmojiEntry(date: Date(), emoji: "🚀"))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
    }
} 