import SwiftUI
import CoreData

struct AnalyticsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching app style
                LinearGradient(
                    gradient: Gradient(colors: colorScheme == .dark ? 
                                      [Color.black, Color.blue.opacity(0.2)] : 
                                      [Color.white, Color.blue.opacity(0.1)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Tab selector
                    Picker("View", selection: $selectedTab) {
                        Text("Stats").tag(0)
                        Text("Streaks").tag(1)
                        Text("Achievements").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()
                    
                    // Tab content
                    TabView(selection: $selectedTab) {
                        StatsView()
                            .tag(0)
                        
                        StreaksView()
                            .tag(1)
                        
                        AchievementsView()
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Analytics")
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            })
        }
    }
}

struct StatsView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var completedChores: [ChoreEntity] = []
    @State private var pendingChores: [ChoreEntity] = []
    @State private var categories: [CategoryEntity] = []
    @State private var timeFrame: TimeFrame = .week
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    enum TimeFrame {
        case day, week, month, all
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time frame selector
                HStack {
                    Button("Day") { timeFrame = .day }
                        .buttonStyle(TimeFrameButtonStyle(isSelected: timeFrame == .day, colorScheme: colorScheme))
                    
                    Button("Week") { timeFrame = .week }
                        .buttonStyle(TimeFrameButtonStyle(isSelected: timeFrame == .week, colorScheme: colorScheme))
                    
                    Button("Month") { timeFrame = .month }
                        .buttonStyle(TimeFrameButtonStyle(isSelected: timeFrame == .month, colorScheme: colorScheme))
                    
                    Button("All") { timeFrame = .all }
                        .buttonStyle(TimeFrameButtonStyle(isSelected: timeFrame == .all, colorScheme: colorScheme))
                }
                .padding(.horizontal)
                
                // Summary cards
                VStack(spacing: 16) {
                    // Completion card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completion Rate")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        HStack(alignment: .bottom, spacing: 8) {
                            let percentage = completionPercentage()
                            Text("\(Int(percentage))%")
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Spacer()
                            
                            // Visual meter
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                    .frame(width: 150, height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green)
                                    .frame(width: 150 * CGFloat(percentage) / 100, height: 8)
                            }
                        }
                        
                        Text("Based on \(completedChores.count + pendingChores.count) chores")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .padding(.horizontal)
                    
                    // Completion counts
                    HStack(spacing: 16) {
                        // Completed
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Completed")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("\(completedChores.count)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                        
                        // Pending
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pending")
                                .font(.headline)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                            
                            Text("\(pendingChores.count)")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                            
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // Category breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category Breakdown")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        ForEach(categories, id: \.id) { category in
                            let categoryChores = categoryChoreCount(for: category)
                            if categoryChores > 0 {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Circle()
                                            .fill(Color(category.color ?? "blue"))
                                            .frame(width: 12, height: 12)
                                        
                                        Text(category.name ?? "Unnamed")
                                            .font(.subheadline)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                        
                                        Spacer()
                                        
                                        Text("\(categoryChores)")
                                            .font(.subheadline)
                                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                    }
                                    
                                    // Progress bar
                                    let percentage = Double(categoryChores) / Double(max(1, completedChores.count + pendingChores.count))
                                    ProgressView(value: percentage)
                                        .tint(Color(category.color ?? "blue"))
                                        .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            loadData()
        }
        .onChange(of: timeFrame) { _, _ in
            loadData()
        }
    }
    
    private func loadData() {
        let calendar = Calendar.current
        let now = Date()
        
        // Set start date based on time frame
        var startDate: Date?
        switch timeFrame {
        case .day:
            startDate = calendar.startOfDay(for: now)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now)
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now)
        case .all:
            startDate = nil
        }
        
        // Fetch all chores, filter based on time frame
        let allChores = coreDataManager.fetchChores(includeCompleted: true)
        
        if let startDate = startDate {
            completedChores = allChores.filter { 
                $0.isCompleted && 
                ($0.completedDate ?? Date.distantPast) >= startDate 
            }
            
            pendingChores = allChores.filter { 
                !$0.isCompleted && 
                ($0.createdDate ?? Date.distantPast) >= startDate 
            }
        } else {
            completedChores = allChores.filter { $0.isCompleted }
            pendingChores = allChores.filter { !$0.isCompleted }
        }
        
        // Fetch categories
        categories = coreDataManager.fetchCategories()
    }
    
    private func completionPercentage() -> Double {
        let total = completedChores.count + pendingChores.count
        guard total > 0 else { return 0 }
        
        return Double(completedChores.count) / Double(total) * 100
    }
    
    private func categoryChoreCount(for category: CategoryEntity) -> Int {
        let allChores = completedChores + pendingChores
        return allChores.filter { $0.category == category }.count
    }
}

struct TimeFrameButtonStyle: ButtonStyle {
    var isSelected: Bool
    var colorScheme: ColorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? 
                          (colorScheme == .dark ? Color.white : Color.black) : 
                          (colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)))
            )
            .foregroundColor(isSelected ? 
                           (colorScheme == .dark ? .black : .white) : 
                           (colorScheme == .dark ? .white : .black))
            .font(.subheadline)
            .fontWeight(isSelected ? .semibold : .regular)
    }
}

struct StreaksView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var streak: StreakEntity?
    @State private var completedByDay: [Date: Int] = [:]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Current streak
                VStack(alignment: .leading, spacing: 12) {
                    Text("Current Streak")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    HStack(alignment: .bottom, spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("\(streak?.currentStreak ?? 0)")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("days")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                            .padding(.bottom, 8)
                    }
                    
                    Text(streakMessage())
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .padding(.horizontal)
                
                // Stats cards
                HStack(spacing: 16) {
                    // Longest streak
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Longest")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("\(streak?.longestStreak ?? 0)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("days")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    
                    // Total completions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total")
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("\(streak?.totalCompletions ?? 0)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Text("chores completed")
                            .font(.caption)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                            .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                }
                .padding(.horizontal)
                
                // Weekly activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last 7 Days")
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    // Day circles
                    HStack(spacing: 6) {
                        ForEach(lastSevenDays(), id: \.self) { date in
                            let count = completedByDay[date] ?? 0
                            VStack(spacing: 4) {
                                Text(dayOfWeek(for: date))
                                    .font(.caption2)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                                
                                ZStack {
                                    Circle()
                                        .fill(count > 0 ? Color.green : (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2)))
                                        .frame(width: 32, height: 32)
                                    
                                    if count > 0 {
                                        Text("\(count)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Text(dayNumber(for: date))
                                    .font(.caption2)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        streak = coreDataManager.getOrCreateStreak()
        let allCompletedChores = coreDataManager.fetchChores(includeCompleted: true).filter { $0.isCompleted }
        
        // Group completed chores by day
        completedByDay = Dictionary(grouping: allCompletedChores) { chore in
            guard let date = chore.completedDate else { return Date() }
            return Calendar.current.startOfDay(for: date)
        }.mapValues { $0.count }
    }
    
    private func lastSevenDays() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<7).map { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
        }.reversed()
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func dayNumber(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private func streakMessage() -> String {
        guard let streak = streak else { return "Complete a chore to start your streak!" }
        
        if streak.currentStreak == 0 {
            return "Complete a chore today to start your streak!"
        } else if streak.currentStreak < 3 {
            return "You're building momentum! Keep it going."
        } else if streak.currentStreak < 7 {
            return "Great job maintaining your streak!"
        } else if streak.currentStreak < 14 {
            return "Impressive consistency! You're developing a solid habit."
        } else {
            return "Amazing discipline! Your consistency is inspiring."
        }
    }
}

struct AchievementsView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var coreDataManager = CoreDataManager.shared
    @State private var achievements: [AchievementEntity] = []
    @State private var selectedFilter: AchievementFilter = .all
    
    enum AchievementFilter {
        case all, unlocked, locked
    }
    
    var filteredAchievements: [AchievementEntity] {
        switch selectedFilter {
        case .all:
            return achievements
        case .unlocked:
            return achievements.filter { $0.isAchieved }
        case .locked:
            return achievements.filter { !$0.isAchieved }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter buttons
            HStack {
                Button("All") { selectedFilter = .all }
                    .buttonStyle(TimeFrameButtonStyle(isSelected: selectedFilter == .all, colorScheme: colorScheme))
                
                Button("Unlocked") { selectedFilter = .unlocked }
                    .buttonStyle(TimeFrameButtonStyle(isSelected: selectedFilter == .unlocked, colorScheme: colorScheme))
                
                Button("Locked") { selectedFilter = .locked }
                    .buttonStyle(TimeFrameButtonStyle(isSelected: selectedFilter == .locked, colorScheme: colorScheme))
            }
            .padding()
            
            if filteredAchievements.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow.opacity(0.5))
                    
                    Text("No achievements to display")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    Text("Keep completing chores to unlock achievements!")
                        .font(.subheadline)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(filteredAchievements, id: \.id) { achievement in
                            AchievementCard(achievement: achievement, colorScheme: colorScheme)
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            loadAchievements()
        }
    }
    
    private func loadAchievements() {
        achievements = coreDataManager.fetchAchievements()
        
        // If no achievements exist, set up defaults
        if achievements.isEmpty {
            coreDataManager.setupDefaultData()
            achievements = coreDataManager.fetchAchievements()
        }
    }
}

struct AchievementCard: View {
    let achievement: AchievementEntity
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: achievement.isAchieved ? "trophy.fill" : "trophy")
                    .font(.title2)
                    .foregroundColor(achievement.isAchieved ? .yellow : .gray)
                
                Text(achievement.name ?? "Unknown Achievement")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Spacer()
                
                if achievement.isAchieved, let date = achievement.achievedDate {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                }
            }
            
            Text(achievement.achievementDescription ?? "")
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.8))
            
            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(achievement.isAchieved ? Color.yellow : Color.blue)
                    .frame(width: max(0, min(UIScreen.main.bounds.width - 64, (UIScreen.main.bounds.width - 64) * CGFloat(achievement.progress / achievement.threshold))), height: 8)
            }
            
            HStack {
                Spacer()
                
                Text(achievement.isAchieved ? "Completed!" : "\(Int(achievement.progress))/\(Int(achievement.threshold))")
                    .font(.caption)
                    .foregroundColor(achievement.isAchieved ? .yellow : (colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white.opacity(0.8))
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.1) : Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
} 