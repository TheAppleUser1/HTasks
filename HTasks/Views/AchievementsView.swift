import SwiftUI

struct AchievementsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var achievementManager: AchievementManager
    @State private var achievements: [AchievementEntity] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(achievements, id: \.id) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Achievements")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .onAppear {
                achievements = achievementManager.fetchAchievements()
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: AchievementEntity
    
    var body: some View {
        HStack {
            Image(systemName: achievement.isCompleted ? "trophy.fill" : "trophy")
                .font(.title2)
                .foregroundColor(achievement.isCompleted ? .yellow : .gray)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(achievement.isCompleted ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.name ?? "")
                    .font(.headline)
                
                Text(achievement.achievementDescription ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                if !achievement.isCompleted {
                    ProgressView(value: Double(achievement.progress),
                               total: Double(achievement.requiredProgress))
                        .tint(.blue)
                    
                    Text("\(achievement.progress)/\(achievement.requiredProgress)")
                        .font(.caption)
                        .foregroundColor(.gray)
                } else if let completedDate = achievement.completedDate {
                    Text("Completed on \(completedDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
} 