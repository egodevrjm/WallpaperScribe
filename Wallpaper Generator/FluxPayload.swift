//
//  Payload.swift
//  Wallpaper Generator
//
//  Created by Ryan Morrison on 9/25/24.

import Foundation

struct FluxPayload: Codable {
    let prompt: String
    let imageSize: String
    let numInferenceSteps: Int
    let numImages: Int
    let enableSafetyChecker: Bool

    enum CodingKeys: String, CodingKey {
        case prompt
        case imageSize = "image_size"
        case numInferenceSteps = "num_inference_steps"
        case numImages = "num_images"
        case enableSafetyChecker = "enable_safety_checker"
    }
}
