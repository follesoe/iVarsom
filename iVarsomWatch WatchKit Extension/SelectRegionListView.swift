import SwiftUI

struct SelectRegionListView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        List {
            ForEach(RegionOption.allOptions) { option in
                Text(option.name)
                    .onTapGesture {
                        print(option.name)
                        self.presentationMode.wrappedValue.dismiss()
                    }
            }
        }
    }
}

struct SelectRegionListView_Previews: PreviewProvider {
    static var previews: some View {
        SelectRegionListView()
    }
}
