/**
 * Copyright 2019 Google ML Kit team
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit

/**
 * An extension of `UIImage` that provides custom image data management.
 */

private let kJPEGCompressionQuality: CGFloat = 0.7

extension UIImage {
  /**
   * Returns a base 64 encoded string for `UIImage`.
   *
   * @return Returns the base 64 encoded string for `UIImage` or `nil` if its JPEG representation is
   *     `nil`.
   */
  func fir_base64EncodedString() -> String? {
    let jpegEncoding = self.jpegData(compressionQuality: kJPEGCompressionQuality)
    return jpegEncoding?.base64EncodedString(options: .lineLength64Characters)
  }
}

func base64EncodedString() {
}


