import SwiftUI

struct RegionDetailView: View {
    var loadingState: LoadState
    var selectedRegion: RegionSummary
    var selectedWarning: AvalancheWarningDetailed?
    @Binding var warnings: [AvalancheWarningDetailed]
    @State private var showWarningText = false
    @State private var showProblemDetails = false
    
    var body: some View {
        TabView {
            if let selectedWarning = selectedWarning {
                WarningSummary(selectedWarning: selectedWarning)
                    .padding(.horizontal)
                    .containerBackground(selectedWarning.DangerLevel.color.gradient, for: .tabView)
                    .navigationTitle(selectedRegion.Name)
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Spacer()
                            Button {
                                showWarningText = true
                            } label: {
                                Label("Details", systemImage: "plus.magnifyingglass")
                            }
                        }
                    }
                    .sheet(isPresented: $showWarningText, content: {
                        MainWarningTextView(selectedWarning: selectedWarning)
                    })
                
                if let problems = selectedWarning.AvalancheProblems {
                    ForEach(problems) { problem in
                        AvalancheProblemView(problem: problem)
                            .containerBackground(problem.DangerLevelEnum.color.gradient, for: .tabView)
                            .toolbar {
                                ToolbarItemGroup(placement: .bottomBar) {
                                    Spacer()
                                    Button {
                                        showProblemDetails = true
                                    } label: {
                                        Label("Details", systemImage: "plus.magnifyingglass")
                                    }
                                }
                            }
                            .sheet(isPresented: $showProblemDetails, content: {
                                AvalancheProblemDetailsView(problem: problem)
                            })
                        
                    }
                    .navigationTitle("Avalanche problem")
                }
            } else {
                VStack {
                    ProgressView();
                    Text("Loading Details")
                }.padding()
            }
            
            ScrollView {
                VStack {
                    let filteredWarnings = warnings.filter { $0.id > 0 }
                    if (loadingState == .loading) {
                        VStack {
                            ProgressView();
                            Text("Loading Details")
                        }.padding()
                    } else {
                        ForEach(filteredWarnings) { warning in
                            HStack(alignment: .center) {
                                Text(formatWarningDay(date: warning.ValidFrom))
                                Spacer()
                                DangerIcon(dangerLevel: warning.DangerLevel)
                                    .frame(width: 34, height: 34)
                                    .padding(.trailing, 8)
                                Text(warning.DangerLevel.description)
                                    .font(.system(size: 26))
                                    .fontWeight(.heavy)
                            }
                            Divider()
                        }
                    }
                    DataSourceView()
                }
                .scenePadding()
            }
            .navigationTitle("Forecast")
        }
        .tabViewStyle(.verticalPage)
        .navigationBarTitleDisplayMode(.automatic)
    }
    
    func formatWarningDay(date: Date) -> String {        
        if (Calendar.current.isDateInYesterday(date) ||
            Calendar.current.isDateInToday(date) ||
            Calendar.current.isDateInTomorrow(date)) {
            return date.getRelativeDayNameAbbr()
        } else {
            return date.getDayName().firstUppercased
        }
    }
}

struct RegionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
        NavigationView {
            RegionDetailView(loadingState: .loaded, selectedRegion: testRegions[1], selectedWarning: warningDetailed[0], warnings: .constant(warningDetailed))
        }
    }
}
