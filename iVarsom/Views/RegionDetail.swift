import SwiftUI

struct RegionDetail: View {
    @Binding var selectedRegion: RegionSummary?
    @Binding var selectedWarning: AvalancheWarningDetailed?
    @Binding var warnings: [AvalancheWarningDetailed]
    @State private var showWarningText = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let selectedWarning = selectedWarning {
                    WarningSummary(
                        warning: selectedWarning,
                        includeLocationIcon: false)
                        .frame(maxWidth: 600)
                        .cornerRadius(10)
                        .padding()
                        .sheet(isPresented: $showWarningText, content: {
                            MainWarningTextView(
                                selectedWarning: selectedWarning,
                                isShowingSheet: $showWarningText)
                        })
                        .onTapGesture(perform: {
                            showWarningText = true
                        })
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { value in
                        HStack(spacing: 8) {
                            ForEach(warnings) { warning in
                                let action = {
                                    withAnimation {
                                        self.selectedWarning = warning
                                        value.scrollTo(warning.id)
                                    }
                                }
                                
                                let isSelected = selectedWarning?.RegId == warning.RegId
                                
                                let cell = DayCell(
                                    dangerLevel: warning.DangerLevel,
                                    date: warning.ValidFrom,
                                    isSelected: isSelected)
                                        .padding(.top, 5)
                                        .id(warning.id)

                                if (isSelected) {
                                    Button(action: action) { cell }.buttonStyle(.borderedProminent)
                                } else {
                                    Button(action: action) { cell }.buttonStyle(.bordered)
                                }
                            }
                            .onAppear {
                                if !warnings.isEmpty, let lastWarning = warnings.filter({ $0.id > 0 }).last {
                                    print("Scroll to \(lastWarning.id)")
                                    value.scrollTo(lastWarning.id)
                                }
                            }
                        }
                    }
                }
                .padding()
                if let selectedWarning = selectedWarning {
                    if let problems = selectedWarning.AvalancheProblems {
                        VStack(alignment: .leading) {
                            Text("Avalanche problems").font(.headline)
                                .padding(.horizontal)
                            ForEach(problems) { problem in
                                AvalancheProblemView(problem: problem)
                                    .padding()
                            }
                        }
                        .frame(maxWidth: 600)
                    }
                    Link("Read complete warning on Varsom.no.", destination: selectedWarning.VarsomUrl)
                        .padding()
                }
            }
        }
        .navigationTitle(selectedRegion?.Name ?? "Region")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview("Region Detail") {
    let warningDetailed: [AvalancheWarningDetailed] = load("DetailedWarning.json")
    return NavigationView {
        RegionDetail(
            selectedRegion: .constant(testRegions[1]),
            selectedWarning: .constant(warningDetailed[0]),
            warnings: .constant(warningDetailed))
    }
}
