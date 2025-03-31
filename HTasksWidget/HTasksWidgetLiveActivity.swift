//
//  HTasksWidgetLiveActivity.swift
//  HTasksWidget
//
//  Created by Apple on 2025. 03. 31..
//

import ActivityKit
import WidgetKit
import SwiftUI

struct HTasksWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct HTasksWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HTasksWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension HTasksWidgetAttributes {
    fileprivate static var preview: HTasksWidgetAttributes {
        HTasksWidgetAttributes(name: "World")
    }
}

extension HTasksWidgetAttributes.ContentState {
    fileprivate static var smiley: HTasksWidgetAttributes.ContentState {
        HTasksWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: HTasksWidgetAttributes.ContentState {
         HTasksWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: HTasksWidgetAttributes.preview) {
   HTasksWidgetLiveActivity()
} contentStates: {
    HTasksWidgetAttributes.ContentState.smiley
    HTasksWidgetAttributes.ContentState.starEyes
}
