import SwiftUI

struct RegionDetailView: View {
    var loadingState: LoadPhase
    var selectedRegion: RegionSummary
    var selectedWarning: AvalancheWarningDetailed?
    let warnings: [AvalancheWarningDetailed]
    @State private var showWarningText = false
    @State private var showProblemDetails = false

    var body: some View {
        TabView {
            if let selectedWarning = selectedWarning {
                WarningSummary(selectedWarning: selectedWarning)
                    .containerBackground(.black, for: .tabView)
                    .navigationTitle(selectedRegion.Name)
                    .toolbar {
                        ToolbarItemGroup(placement: .bottomBar) {
                            Spacer()
                            Button {
                                showWarningText = true
                            } label: {
                                Label("Details", systemImage: "plus.magnifyingglass")
                                    .labelStyle(.iconOnly)
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
                                            .labelStyle(.iconOnly)
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
                Group {
                    switch loadingState {
                    case .idle, .loading:
                        VStack {
                            ProgressView()
                            Text("Loading Details")
                        }
                    case .failed:
                        Text("Service unavailable")
                    case .loaded:
                        Text("No warning available")
                    }
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
                                    .font(.title2.weight(.heavy))
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(formatWarningDay(date: warning.ValidFrom)), \(String(localized: "Danger level \(warning.DangerLevel.description), \(warning.DangerLevel.localizedName)"))")
                            Divider()
                        }
                    }
                    DataSourceView(source: Country.from(regionId: selectedRegion.Id) == .sweden ? .sweden : .norway)
                }
                .scenePadding()
            }
            .navigationTitle("Forecast")
        }
        .tabViewStyle(.verticalPage)
        .navigationBarTitleDisplayMode(.automatic)
    }

    func formatWarningDay(date: Date) -> String {
        ForecastSelection.dayLabel(date, regionID: selectedRegion.Id, now: .current)
    }
}

#Preview("Region Detail") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return NavigationStack {
        RegionDetailView(loadingState: .loaded, selectedRegion: testRegions[1], selectedWarning: warningDetailed[0], warnings: warningDetailed)
    }
}
