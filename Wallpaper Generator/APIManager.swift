//
//  APIManager.swift
//  Wallpaper Generator
//
//  Created by Ryan Morrison on 9/24/24.
//

import Foundation
import UIKit

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(String)
    case decodingError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid. Please try again later."
        case .invalidResponse:
            return "Received an invalid response from the server. Please try again."
        case .serverError(let message):
            return "Server Error: \(message)"
        case .decodingError:
            return "Failed to process the data from the server."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
}

struct APIResponse: Codable {
    let image_url: String
}

class APIManager {
    static let shared = APIManager()
    private let apiKey: String
    
    private init() {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["FALAI_API_KEY"] as? String {
            self.apiKey = key
        } else {
            fatalError("API Key is missing. Please add it to Secrets.plist.")
        }
    }
    
    func generateWallpaper(with prompt: String, imageSize: CGSize = CGSize(width: 1080, height: 1920), steps: Int = 50, safetyFilters: Bool = true, completion: @escaping (Result<UIImage, Error>) -> Void) {
        let parameters: [String: Any] = [
            "model": "flux.1 [schnell]",
            "prompt": prompt,
            "image_size": [
                "width": imageSize.width,
                "height": imageSize.height
            ],
            "steps": steps,
            "safety_filters": safetyFilters
        ]
        
        guard let url = URL(string: "https://api.fal.ai/generate") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(NetworkError.decodingError))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(NetworkError.serverError(error.localizedDescription)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            
            // Assuming the API returns image data directly. Adjust based on actual API response.
            if let image = UIImage(data: data) {
                completion(.success(image))
            } else {
                completion(.failure(NetworkError.decodingError))
            }
        }
        task.resume()
    }
}
