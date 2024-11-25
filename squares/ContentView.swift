import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var authManager: StravaAuthManager
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            VStack {
                TabView(selection: $selectedTab) {
                    VStack {
                        Text("Notes")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        SubjectsPage(context: viewContext)
                    }
                    .tag(0)
                    
                    VStack {
                        //Text("Squares")
                        //   .font(.largeTitle)
                        //    .foregroundColor(.orange)
                        SquaresView()
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .tag(1)
                    
                    VStack {
                        Text("Body Metrics")
                        BodyMetricsView()
                    }
                    .tag(2)  // Or whatever tag number works for your navigation
                    
                    VStack {
                        AddActivity()
                            .environmentObject(authManager)
                            .environment(\.managedObjectContext, viewContext)
                    }
                    .tag(3)

                    /*VStack {
                        NoteGraphView()
                    }
                    .tag(4)*/
                    
                    
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                HStack {
                    Button(action: {
                        selectedTab = 0
                    }) {
                        VStack {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 30))
                                .foregroundColor(Color(.systemOrange))
                            if selectedTab == 0 {
                                // WHEN SELECTED
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Button(action: {
                        selectedTab = 1
                    }) {
                        VStack {
                            Image(systemName: "square.3.stack.3d.middle.filled")
                                .font(.system(size: 30))
                                .foregroundColor(Color(.systemOrange))
                            if selectedTab == 1 {
                                // WHEN SELECTED
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Button(action: {
                        selectedTab = 2  // Or whatever tag number you used
                    }) {
                        VStack {
                            Image(systemName: "scalemass")
                                .font(.system(size: 30))
                                .foregroundColor(Color(.systemOrange))
                            if selectedTab == 2 {
                                // Selected state styling if needed
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    

                    Button(action: {
                        selectedTab = 3
                    }) {
                        VStack {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 30))
                                .foregroundColor(Color(.systemOrange))
                            if selectedTab == 3 {
                                // WHEN SELECTED
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                
                    // Note exploring this path for now
                    /*Button(action: {
                        selectedTab = 3
                    }) {
                        VStack {
                            Image(systemName: "brain")
                                .font(.system(size: 30))
                                .foregroundColor(Color(.systemOrange))
                            if selectedTab == 3 {
                                // WHEN SELECTED
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)*/
                }
                .padding()
            }
            .background(Color(red: 14 / 255, green: 17 / 255, blue: 22 / 255))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(StravaAuthManager())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
