import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                selectedTab = 0
            }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == 0 ? .blue : .gray)
            }
            
            Spacer()
            
            Button(action: {
                selectedTab = 1
            }) {
                Image(systemName: "chart.bar")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == 1 ? .blue : .gray)
            }
            
            Spacer()
            
            Button(action: {
                selectedTab = 2
            }) {
                Image(systemName: "gear")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == 2 ? .blue : .gray)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 2)
    }
} 