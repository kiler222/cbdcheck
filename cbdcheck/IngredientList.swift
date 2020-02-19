//
//  IngredientList.swift
//  cbdcheck
//
//  Created by kiler on 30/11/2019.
//  Copyright © 2019 kiler. All rights reserved.
//

import SwiftUI

struct IngredientList: View {
    var ingredientList: [Ingredient]
    var body: some View {
       List(ingredientList) { ingredient in
            IngredientRow(ingredient: ingredient)
        
        }
    }
}

struct LandmarkList_Previews: PreviewProvider {
    static var previews: some View {
        IngredientList(ingredientList: fakeData)
    }
}
