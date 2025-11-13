//
//  TextRecognitionService.swift
//  Clast
//
//  Created by Alexander McGreevy on 11/13/25.
//

import UIKit
import Vision

class TextRecognitionService {
    static let shared = TextRecognitionService()
    
    private init() {}
    
    /// Extract text from a UIImage using Vision framework
    func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw TextRecognitionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: TextRecognitionError.recognitionFailed(error))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: TextRecognitionError.noTextFound)
                    return
                }
                
                let recognizedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                if recognizedText.isEmpty {
                    continuation.resume(throwing: TextRecognitionError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedText)
                }
            }
            
            // Configure for maximum accuracy
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"] // Add more languages as needed
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: TextRecognitionError.recognitionFailed(error))
            }
        }
    }
    
    /// Extract text from multiple images and combine
    func recognizeText(from images: [UIImage]) async throws -> String {
        var allText: [String] = []
        
        for image in images {
            let text = try await recognizeText(from: image)
            allText.append(text)
        }
        
        return allText.joined(separator: "\n\n---\n\n")
    }
}

// MARK: - Error Types

enum TextRecognitionError: LocalizedError {
    case invalidImage
    case recognitionFailed(Error)
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image format"
        case .recognitionFailed(let error):
            return "Text recognition failed: \(error.localizedDescription)"
        case .noTextFound:
            return "No text found in image"
        }
    }
}
