import SwiftUI

struct HomeView: View {
    @Binding var tasks: [HTTask]
    @State private var taskToDelete: HTTask?
    @State private var showingDeleteAlert = false
    @State private var showingAddTaskSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingAchievementsSheet = false
    @State private var showingStatisticsSheet = false
    @State private var showingChatSheet = false
    @State private var showingFeedSheet = false
    @State private var newTaskTitle = ""
    @State private var newTaskDueDate: Date = Date()
    @State private var showDatePicker = false
    @State private var settings = UserSettings.defaultSettings
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedPriority: TaskPriority = .easy
    @State private var selectedCategory: TaskCategory = .personal

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Button(action: {
                    showingStatisticsSheet = true
                }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? .white : .black)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                }
                .padding(.leading, 20)
                .padding(.bottom, 20)
                
                Spacer()
                
                Button(action: {
                    showingFeedSheet = true
                }) {
                    Image(systemName: "newspaper.fill")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? .white : .black)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                }
                .padding(.bottom, 20)
                
                Spacer()
                
                Button(action: {
                    showingAddTaskSheet = true
                }) {
                    Image(systemName: "plus")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                        .frame(width: 60, height: 60)
                        .background(
                            Circle()
                                .fill(colorScheme == .dark ? .white : .black)
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }

        .sheet(isPresented: $showingFeedSheet) {
            FeedView()
        }
    }
} 