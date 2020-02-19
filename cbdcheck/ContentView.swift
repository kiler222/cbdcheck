//
//  ContentView.swift
//  cbdcheck
//
//  Created by kiler on 25/11/2019.
//  Copyright © 2019 kiler. All rights reserved.
//
//
//  ContentView.swift
//  CameraAndGalleryTutorial
//
//  Created by Duy Bui on 10/26/19.
//  Copyright © 2019 Duy Bui. All rights reserved.
//

import SwiftUI
import URLImage


  



struct ViewControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = VideoCamViewController


    func makeUIViewController(context: UIViewControllerRepresentableContext<ViewControllerWrapper>) -> ViewControllerWrapper.UIViewControllerType {
        return VideoCamViewController()
    }

    func updateUIViewController(_ uiViewController: ViewControllerWrapper.UIViewControllerType, context: UIViewControllerRepresentableContext<ViewControllerWrapper>) {
        //
    }
}



struct ContentView: View {
  
     var product: Product
    var color: Color
    
    var ingredientList: [Ingredient]
    
    init(product: Product, color: Color, ingredientList: Array<Ingredient>){
           UITableView.appearance().backgroundColor = .clear
        self.product = product
        self.color = color
        self.ingredientList = ingredientList
       }
    
  var body: some View {


    VStack {
        
        
        HStack {
//            Image("cbdcheck")
//                .resizable()
//                .frame(width: 100.0, height: 100.0)
//                .aspectRatio(1, contentMode: .fill)
            
            URLImage(product.url!) { proxy in
                proxy.image
                    .resizable()                     // Make image resizable
                    .aspectRatio(contentMode: .fill) // Fill the frame
                    .clipped()                       // Clip overlaping parts
            }
            .frame(width: 160.0, height: 100.0)  // Set frame to 100x100.
            
            
            VStack(alignment: .leading) {
                                    
                Text(verbatim: product.productName!)
                .font(.system(size: 24))
                //).font(.title)
                
                Text(verbatim: product.brand!)
                        .font(.subheadline)
                
                 HStack {
                    
                    Image("circle.fill")
                        .foregroundColor(color)
                            
                    VStack(alignment: .leading) {
                        Text("\(product.score!) / 100")
                         .font(.subheadline)

                        Text(product.status!)
                        .font(.system(size: 10))
                        
                    }
                    
                }
                
            }
            Spacer()
        }
     
        IngredientList(ingredientList: ingredientList)
            .listStyle(GroupedListStyle())
                

//        Divider()

        Button(action: {

            let link = "https://www.google.com/search?q=\(self.product.itemNo!)"

            UIApplication.shared.open(URL(string: link)!)

        }) {
        Text(verbatim: "See more...")
        }
        
     }
     .padding()

  }
  
}



struct MyCamView : View {
    var body: some View {
        ViewControllerWrapper()
    }
}


struct ContentView_Preview: PreviewProvider {
    static var previews: some View {
        ContentView(product: fakeProduct, color: Color.black, ingredientList: fakeData)
    }
}


