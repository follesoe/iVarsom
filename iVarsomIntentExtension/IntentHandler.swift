import Intents
import CoreLocation

class IntentHandler: INExtension, SelectRegionIntentHandling {
    
    func provideRegionOptionsCollection(for intent: SelectRegionIntent, with completion: @escaping (INObjectCollection<RegionConfigOption>?, Error?) -> Void) {        
        let options = CLLocationManager().isAuthorizedForWidgetUpdates ?
            RegionOption.allOptions : RegionOption.aRegions
        
        let regions: [RegionConfigOption] = options.map { region in
            let option = RegionConfigOption(
                identifier: "\(region.id)",
                display: region.name)
            option.regionId = NSNumber(value: region.id)
            return option
        }
            
        let collection = INObjectCollection(items: regions)
        completion(collection, nil);
    }

    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        return self
    }
}
