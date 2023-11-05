import SwiftUI

struct RegionDetailView: View {
    var loadingState: LoadState
    var selectedRegion: RegionSummary
    var selectedWarning: AvalancheWarningSimple
    @Binding var warnings: [AvalancheWarningSimple]
    
    var body: some View {
        TabView {
            VStack(alignment: .leading) {
                HStack {
                    DangerIcon(dangerLevel: selectedWarning.DangerLevel)
                        .frame(width: 36, height: 36)
                    Spacer()
                    Text("\(selectedWarning.DangerLevel.description)")
                        .font(.system(size: 36))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)
                }
                Text(selectedWarning.ValidFrom.formatted(
                    Date.FormatStyle()
                        .day(.defaultDigits)
                        .weekday(.wide)
                        .month(.abbreviated))
                    .firstUppercased
                )
                .fontWeight(.bold)
                .foregroundColor(.white)
                Text(selectedWarning.MainText)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
            }
            .padding()
            .containerBackground(selectedWarning.DangerLevel.color.gradient, for: .tabView)
            .cornerRadius(14)
            .navigationTitle(selectedRegion.Name)
            
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
        NavigationView {
            RegionDetailView(loadingState: .loaded, selectedRegion: testRegions[1], selectedWarning: testWarningLevel2, warnings: .constant([AvalancheWarningSimple]()))
        }
    }
}
