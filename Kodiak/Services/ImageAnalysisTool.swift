//
//  ImageAnalysisTool.swift
//  Kodiak
//
//  Created by Assistant on 13/08/2025.
//

import Foundation
import FoundationModels

struct ImageAnalysisTool: Tool {
    let name = "analyzeImage"
    let description = "Analyze an attached image and return a summary. Prefer using the latest attached image if no id is provided. Always use this tool when the user asks questions about an attached image."

    @Generable
    struct Arguments {
        @Guide(description: "Optional UUID string of the image attachment to analyze. If omitted, analyze the most recently attached image.")
        var attachmentId: String?
        @Guide(description: "Optional analysis focus or question (e.g., 'what's on the whiteboard?')")
        var focus: String?
    }

    func call(arguments: Arguments) async throws -> String {
        let id: UUID? = {
            if let s = arguments.attachmentId, let uuid = UUID(uuidString: s) { return uuid }
            return AttachmentRegistry.shared.latestImageId
        }()
        guard let id else { return "No recent image found to analyze." }
        #if os(iOS)
        guard let data = AttachmentRegistry.shared.imageData(for: id) else {
            return "No image data found for attachment id \(id.uuidString)."
        }
        return try await analyzeImageData(data, focus: arguments.focus)
        #else
        return "Image analysis is only supported on iOS."
        #endif
    }
}

#if os(iOS)
import Vision
import UIKit

private func analyzeImageData(_ data: Data, focus: String?) async throws -> String {
    guard let image = UIImage(data: data), let cgImage = image.cgImage else {
        return "Unable to decode image."
    }

    // Text (robust on simulator and device)
    let textReq = VNRecognizeTextRequest()
    textReq.recognitionLevel = .accurate
    if #available(iOS 16.0, *) { textReq.usesLanguageCorrection = true }
    let textHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? textHandler.perform([textReq])
    let textLines: [String] = (textReq.results ?? []).compactMap { $0.topCandidates(1).first?.string }
    let ocrText = textLines.joined(separator: "\n")

    // Classification (may fail on simulator with espresso error). Best-effort only.
    var labels: [String] = []
    #if targetEnvironment(simulator)
    // Skip classification on simulator to avoid espresso context errors
    #else
    let classifyReq = VNClassifyImageRequest()
    classifyReq.usesCPUOnly = true
    let classifyHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? classifyHandler.perform([classifyReq])
    labels = (classifyReq.results ?? []).prefix(8).map { result in
        let confidence = Int((result.confidence * 100).rounded())
        return "\(result.identifier) (\(confidence)%)"
    }
    #endif

    // Barcodes (best-effort)
    let barcodeReq = VNDetectBarcodesRequest()
    let barcodeHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? barcodeHandler.perform([barcodeReq])
    let barcodes: [String] = (barcodeReq.results ?? []).compactMap { $0.payloadStringValue }

    var parts: [String] = []
    if !labels.isEmpty { parts.append("Detected objects: \n- " + labels.joined(separator: "\n- ")) }
    if !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { parts.append("Recognized text:\n\n" + ocrText) }
    if !barcodes.isEmpty { parts.append("Barcodes: \n- " + barcodes.joined(separator: "\n- ")) }
    if parts.isEmpty { parts.append("No significant objects, text, or barcodes detected.") }

    let focusLine = (focus?.isEmpty ?? true) ? "" : "\n\nFocus: \(focus!)"
    return "Image analysis summary:\n\n" + parts.joined(separator: "\n\n") + focusLine
}
#endif


