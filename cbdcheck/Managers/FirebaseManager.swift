//
//  FirebaseManager.swift
//  cbdcheck
//
//  Created by kiler on 27/11/2019.
//  Copyright © 2019 kiler. All rights reserved.
//

import Foundation
import FirebaseDatabase

class FirebaseManager: NSObject {
public var token : String?
static let sharedInstance  = FirebaseManager()
 var ref: DatabaseReference!

 

    func checkBarcode(barcode: String, completion: @escaping (NSDictionary) -> Void){
        ref = Database.database().reference()
    
        ref.child("products").child(barcode).observeSingleEvent(of: .value, with: { (snapshot) in
            print("PJ snapshot \(snapshot)")


          let value = snapshot.childSnapshot(forPath: "0").value as? NSDictionary

            print("PJ value ze snapshotu \(snapshot.childSnapshot(forPath: "0").value as? NSDictionary)")
            
            completion(value ?? ["error": "no barcode found"])
         
          }) { (error) in
            let errorDict : NSDictionary = [
                "error" : "\(error.localizedDescription)"
            ]
            print(error.localizedDescription)
            completion(errorDict)
        }
        
        
        

    
    }

}
