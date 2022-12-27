import Foundation

struct UrlUtils {
    /**
     Extract an integer query string parameter from an url.
     
     - Parameters:
        - url: The URL to extract parameter from
        - name: The name of the paramter
     
     - Returns: An optional Int with the parameter value if found
     */
    public static func extractParam(url: URL, name: String) -> Int? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let queryItems = components?.queryItems {
            if let queryItem = queryItems.first(where: { $0.name == name && $0.value != nil}) {
                return Int(queryItem.value ?? "0") ?? 0
            }
        }
        return nil
    }
}
