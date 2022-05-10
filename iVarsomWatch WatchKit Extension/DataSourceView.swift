import SwiftUI

struct DataSourceView: View {
    var body: some View {
        Text("Data from the The Norwegian Avalanche Warning Service and www.varsom.no.")
            .font(.system(size: 11))
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
    }
}

struct DataSourceView_Previews: PreviewProvider {
    static var previews: some View {
        DataSourceView()
    }
}
