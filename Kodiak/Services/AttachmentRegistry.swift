//
//  AttachmentRegistry.swift
//  Kodiak
//
//  Created by Assistant on 13/08/2025.
//

import Foundation

final class AttachmentRegistry {
	static let shared = AttachmentRegistry()
	private init() {}

	private var imageDataById: [UUID: Data] = [:]
	private var pdfURLById: [UUID: URL] = [:]
    private(set) var latestImageId: UUID?
    private(set) var latestPDFId: UUID?

	func registerImage(data: Data, for id: UUID) {
		imageDataById[id] = data
        latestImageId = id
	}

	func imageData(for id: UUID) -> Data? {
		imageDataById[id]
	}

	func registerPDF(url: URL, for id: UUID) {
		pdfURLById[id] = url
        latestPDFId = id
	}

	func pdfURL(for id: UUID) -> URL? {
		pdfURLById[id]
	}
}


