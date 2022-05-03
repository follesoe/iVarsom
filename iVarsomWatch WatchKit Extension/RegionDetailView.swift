import SwiftUI

struct RegionDetailView<ViewModelType: RegionDetailViewModelProtocol>: View {
    @ObservedObject var vm: ViewModelType
    let relativeFormatter: DateFormatter
    let dateFormatter: DateFormatter
    
    var textColor: Color {
        return vm.selectedWarning.DangerLevel == .level2 ? .black : .white;
    }
    
    init (vm: ViewModelType) {
        self.vm = vm
        relativeFormatter = DateFormatter()
        relativeFormatter.timeStyle = .none
        relativeFormatter.dateStyle = .short
        relativeFormatter.doesRelativeDateFormatting = true
        
        dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .full
    }
    
    var body: some View {
        ScrollView {
            VStack {
                ZStack {
                    DangerGradient(dangerLevel: vm.selectedWarning.DangerLevel)
                    VStack(alignment: .leading) {
                        HStack {
                            DangerIcon(dangerLevel: vm.selectedWarning.DangerLevel)
                                .frame(width: 36, height: 36)
                            Spacer()
                            Text("\(vm.selectedWarning.DangerLevel.description)")
                                .font(.system(size: 36))
                                .fontWeight(.heavy)
                                .foregroundColor(textColor)
                        }
                        Text(vm.selectedWarning.ValidFrom.formatted(
                            Date.FormatStyle()
                                .day(.defaultDigits)
                                .weekday(.wide)
                                .month(.abbreviated)))
                            .fontWeight(.bold)
                            .foregroundColor(textColor)
                        Text(vm.selectedWarning.MainText)
                            .foregroundColor(textColor)
                    }
                    .padding()
                }.cornerRadius(14)
                
                let filteredWarnings = vm.warnings.filter { $0.id > 0 }
                if (filteredWarnings.count > 0) {
                    Divider()
                }

                ForEach(filteredWarnings) { warning in
                    HStack(alignment: .center) {
                        Text(formatWarningDay(date: warning.ValidFrom))
                        Spacer()
                        DangerIcon(dangerLevel: warning.DangerLevel)
                            .frame(width: 34, height: 34)
                            .padding(.trailing, 8)
                        Text("\(warning.DangerLevel.rawValue)")
                            .font(.system(size: 26))
                            .fontWeight(.heavy)
                    }
                    Divider()
                }
            }
        }
        .navigationTitle(vm.regionSummary.Name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await self.vm.loadWarnings(from: -1, to: 2)
        }
    }
    
    func formatWarningDay(date: Date) -> String {
        
        if (Calendar.current.isDateInYesterday(date) ||
            Calendar.current.isDateInToday(date) ||
            Calendar.current.isDateInTomorrow(date)) {
            return relativeFormatter.string(from: date).firstUppercased
        } else {
            return date.getDayName().firstUppercased
        }
    }
}

struct RegionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegionDetailView(
                vm: DesignTimeRegionDetailViewModel(
                    regionSummary: testVarsomData.regions[2]))
        }
    }
}
