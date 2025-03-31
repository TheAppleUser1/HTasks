import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> TimeEmojiEntry {
        TimeEmojiEntry(date: Date(), emoji: "😊")
    }

    func getSnapshot(in context: Context, completion: @escaping (TimeEmojiEntry) -> ()) {
        let entry = TimeEmojiEntry(date: Date(), emoji: "😊")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [TimeEmojiEntry] = []
        let currentDate = Date()
        
        // Create a timeline with entries every 5 minutes for the next hour
        for minuteOffset in stride(from: 0, to: 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            
            // Different emojis for different times
            let emoji = getRandomEmoji(for: entryDate)
            let entry = TimeEmojiEntry(date: entryDate, emoji: emoji)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    func getRandomEmoji(for date: Date) -> String {
        let emojis = ["😊", "🥳", "🚀", "🔥", "✨", "💫", "🌈", "🦄", "🎉", "❤️", "🌟", "💪"]
        let minute = Calendar.current.component(.minute, from: date)
        let index = minute % emojis.count
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
                                  [Color.black, Color.purple.opacity(0.3)] : 
                                  [Color.white, Color.purple.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 10) {
                // Emoji
                Text(entry.emoji)
                    .font(.system(size: 60))
                
                // Time
                Text(entry.date, style: .time)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                // Date
                Text(entry.date, style: .date)
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
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
                                  [Color.black, Color.purple.opacity(0.3)] : 
                                  [Color.white, Color.purple.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            HStack(spacing: 30) {
                // Emoji
                Text(entry.emoji)
                    .font(.system(size: 80))
                
                VStack(alignment: .leading, spacing: 8) {
                    // Time
                    Text(entry.date, style: .time)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    // Date
                    Text(entry.date, style: .date)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                    
                    Text("Updated \(entry.date, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
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
                                  [Color.black, Color.purple.opacity(0.3)] : 
                                  [Color.white, Color.purple.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            VStack(spacing: 25) {
                // Title
                Text("Time & Emoji")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                // Main emoji
                Text(entry.emoji)
                    .font(.system(size: 120))
                
                // Current time
                VStack {
                    Text(entry.date, style: .time)
                        .font(.system(size: 46, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text(entry.date, style: .date)
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                
                // Additional emojis in a row
                HStack(spacing: 15) {
                    ForEach(additionalEmojis.prefix(5), id: \.self) { emoji in
                        Text(emoji)
                            .font(.system(size: 30))
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