import SwiftUI

enum DataSourceType {
    case norway
    case sweden
    case both
}

struct DataSourceView: View {
    var source: DataSourceType = .both

    var body: some View {
        Text(attributionText)
            .font(.system(size: 11))
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
    }

    private var attributionText: String {
        switch source {
        case .norway:
            return String(localized: "Data from The Norwegian Avalanche Warning Service.")
        case .sweden:
            return String(localized: "Data from Swedish Environmental Protection Agency.")
        case .both:
            return String(localized: "Data from The Norwegian Avalanche Warning Service and Swedish Environmental Protection Agency.")
        }
    }
}

struct DataSourceView_Previews: PreviewProvider {
    static var previews: some View {
        DataSourceView()
    }
}
