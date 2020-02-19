//
//  data.swift
//  cbdcheck
//
//  Created by kiler on 30/11/2019.
//  Copyright © 2019 kiler. All rights reserved.
//

import Foundation


let x = Ingredient(id: UUID(), name: "Jeden", status: "stan")
let y = Ingredient(id: UUID(), name: "Dwa", status: "stan")
let z = Ingredient(id: UUID(), name: "Trzy", status: "stan")

let fakeData : [Ingredient] = [x,y,z]

let fakeProduct = Product(productName: "Pod preview", score: "24", itemNo: "112412512", imageURL: "", url: URL(fileURLWithPath: "https://images.barcodelookup.com/15951/159518597-1.jpg"), priceFullText: "sto", productTypeName: "olej", brand: "good4u")


// var id: Int
//    var name: String
//    fileprivate var imageName: String
////    fileprivate var coordinates: Coordinates
//    var state: String
//    var park: String
//    var category: Category
