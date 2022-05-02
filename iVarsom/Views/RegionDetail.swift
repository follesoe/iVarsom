import SwiftUI

struct RegionDetail<ViewModelType: RegionDetailViewModelProtocol>: View {
    @StateObject var vm: ViewModelType
    @Environment(\.openURL) var openURL
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let warning = vm.selectedWarning {
                    WarningSummary(warning: warning)
                        .frame(maxWidth: 600)
                        .cornerRadius(10)
                        .padding()
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    ScrollViewReader { value in
                        HStack(spacing: 8) {
                            ForEach(vm.warnings.filter { $0.id > 0 }) { warning in
                                let action = {
                                    withAnimation {
                                        self.vm.selectedWarning = warning
                                        value.scrollTo(warning.id)
                                    }
                                }
                                
                                let isSelected = vm.selectedWarning.id == warning.id
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
                                if let lastWarning = vm.warnings.filter({ $0.id > 0 }).last {
                                    print("Scroll to \(lastWarning.id)")
                                    value.scrollTo(lastWarning.id)
                                }
                            }
                        }
                    }
                }
                .padding()
                                
                Link("Read complete warning on Varsom.no", destination: vm.selectedWarning.VarsomUrl)
                    .padding()
            }
        }
        .navigationTitle(vm.regionSummary.Name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await self.vm.loadWarnings(from: -5, to: 2)
        }
    }
}

struct RegionDetail_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RegionDetail(
                vm: DesignTimeRegionDetailViewModel(
                    regionSummary: testVarsomData.regions[2]))
        }
    }
}
