import SwiftUI

struct RegionDetailView<ViewModelType: RegionDetailViewModelProtocol>: View {
    @StateObject var vm: ViewModelType
    
    var textColor: Color {
        return vm.selectedWarning.DangerLevel == .level2 ? .black : .white;
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
                        Text(vm.selectedWarning.MainText)
                            .foregroundColor(textColor)
                    }
                    .padding()
                }.cornerRadius(14)
                Divider()
                ForEach(vm.warnings.filter { $0.id > 0 }) { warning in
                    HStack(alignment: .center) {
                        Text(warning.ValidFrom.getDayName())
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
            await self.vm.loadWarnings()
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
