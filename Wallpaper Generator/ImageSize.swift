//
//  ImageSize.swift
//  Wallpaper Generator
//
//  Created by Ryan Morrison on 9/25/24.
//
// ImageSize.swift
// ImageSize.swift
import Foundation
import UIKit

enum ImageSize: String, Codable {
    case square_hd
    case square
    case portrait_4_3
    case portrait_16_9
    case landscape_4_3
    case landscape_16_9
}

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
