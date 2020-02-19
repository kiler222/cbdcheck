//
//  IngredientRow.swift
//  cbdcheck
//
//  Created by kiler on 30/11/2019.
//  Copyright © 2019 kiler. All rights reserved.
//

import SwiftUI

struct IngredientRow: View {
    
    var ingredient: Ingredient
    
    var body: some View {
        HStack {
//            ingredient.image
//                .resizable()
//                .frame(width: 50, height: 50)
            Text(ingredient.name)
//            Text(ingredient.status)
            Spacer()
            if ingredient.status == "bad" {
                Image("circle.fill")
                .foregroundColor(Color.red)
            } else if (ingredient.status == "good") {
                Image("circle.fill")
                .foregroundColor(Color.green)
            } else {
                Image("circle.fill")
                .foregroundColor(Color.orange)

            }
            
        }
    }
}

struct IngredientRow_Previews: PreviewProvider {
    static var previews: some View {
        Group {
        IngredientRow(ingredient: fakeData[0])
        IngredientRow(ingredient: fakeData[0])
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
