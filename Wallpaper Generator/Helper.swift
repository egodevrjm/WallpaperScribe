//
//  Helper.swift
//  Wallpaper Generator
//
//  Created by Ryan Morrison on 9/25/24.
//

import UIKit

extension UIImage {
    // Convert UIImage array to Data
    static func convertImagesToDataArray(images: [UIImage]) -> Data {
        let imageArrayData = images.compactMap { image -> Data? in
            return image.jpegData(compressionQuality: 0.8)
        }
        return try! NSKeyedArchiver.archivedData(withRootObject: imageArrayData, requiringSecureCoding: false)
    }
    
    // Convert Data to UIImage array
    static func convertDataArrayToImages(dataArray: Data) -> [UIImage]? {
        guard let imageDataArray = try! NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(dataArray) as? [Data] else { return nil }
        return imageDataArray.compactMap { UIImage(data: $0) }
    }
}
