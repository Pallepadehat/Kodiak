//
//  OCRService.swift
//  Kodiak
//
//  Created by Assistant on 13/08/2025.
//

import Foundation

#if os(iOS)
import Vision
import PDFKit
import UIKit

enum OCRServiceError: Error { case invalidInput }

final class OCRService {

	func recognizeText(from image: UIImage) async throws -> String {
		guard let cg = image.cgImage else { throw OCRServiceError.invalidInput }
		let request = VNRecognizeTextRequest()
		request.recognitionLevel = .accurate
		if #available(iOS 16.0, *) { request.usesLanguageCorrection = true }
		let handler = VNImageRequestHandler(cgImage: cg, options: [:])
		try handler.perform([request])
		let observations = request.results ?? []
		let lines = observations.compactMap { $0.topCandidates(1).first?.string }
		return lines.joined(separator: "\n")
	}

	func extractText(from pdf: PDFDocument, maxPages: Int = 10) async throws -> String {
		var parts: [String] = []
		let pageCount = min(pdf.pageCount, maxPages)
		for index in 0..<pageCount {
			guard let page = pdf.page(at: index) else { continue }
			if let pageText = page.string, !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
				parts.append(pageText)
			} else {
				// Fallback: render to image and OCR
				let pageBounds = page.bounds(for: .mediaBox)
				uploadAutoreleasepool: do {
					UIGraphicsBeginImageContextWithOptions(pageBounds.size, true, 2)
					guard let ctx = UIGraphicsGetCurrentContext() else { break }
					UIColor.white.setFill()
					ctx.fill(pageBounds)
					ctx.saveGState()
					ctx.translateBy(x: 0, y: pageBounds.size.height)
					ctx.scaleBy(x: 1.0, y: -1.0)
					ctx.interpolationQuality = .high
					page.draw(with: .mediaBox, to: ctx)
					ctx.restoreGState()
					let image = UIGraphicsGetImageFromCurrentImageContext()
					UIGraphicsEndImageContext()
					if let image = image {
						let text = try await recognizeText(from: image)
						parts.append(text)
					}
				}
			}
		}
		return parts.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
	}
}

#else
final class OCRService {}
#endif


