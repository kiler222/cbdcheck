import SwiftUI
import CoreLocation


struct Ingredient: Hashable, Codable, Identifiable {
    var id: UUID
    var name: String
    var status: String
    


    enum Category: String, CaseIterable, Codable, Hashable {
        case featured = "Featured"
        case lakes = "Lakes"
        case rivers = "Rivers"
    }
    
   
}

extension Ingredient {
    
    var image: Image {
        return Image("cbdcheck")
        //ImageStore.shared.image(name: imageName)
    }
}

//struct Coordinates: Hashable, Codable {
//    var latitude: Double
//    var longitude: Double
//}
