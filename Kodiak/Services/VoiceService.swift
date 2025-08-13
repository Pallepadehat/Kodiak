//
//  VoiceService.swift
//  Kodiak
//
//  Created by Assistant on 13/08/2025.
//

import Foundation

#if os(iOS)
import AVFoundation
import Speech
import UIKit

extension Notification.Name {
    static let voiceDidFinishSpeaking = Notification.Name("VoiceServiceDidFinishSpeaking")
}

@MainActor
final class VoiceService: NSObject {

	private let audioEngine = AVAudioEngine()
	private var speechRecognizer: SFSpeechRecognizer?
	private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
	private var recognitionTask: SFSpeechRecognitionTask?

	private let speechSynthesizer = AVSpeechSynthesizer()

	private(set) var isListening: Bool = false
	private(set) var isSpeaking: Bool = false

	override init() {
		super.init()
		speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
		speechSynthesizer.delegate = self
	}

	func startListening(
		onPartial: @escaping (String) -> Void,
		onFinal: @escaping (String) -> Void,
		onError: @escaping (Error) -> Void
	) {
		// Stop any ongoing recognition
		stopListening()

		let request = SFSpeechAudioBufferRecognitionRequest()
		request.shouldReportPartialResults = true
		if #available(iOS 16.0, *) {
			request.addsPunctuation = true
		}
		self.recognitionRequest = request

		let inputNode = audioEngine.inputNode
		let recordingFormat = inputNode.outputFormat(forBus: 0)
		inputNode.removeTap(onBus: 0)
		inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
			self?.recognitionRequest?.append(buffer)
		}

		audioEngine.prepare()
		do {
			try audioEngine.start()
			isListening = true
		} catch {
			onError(error)
			return
		}

		guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
			onError(NSError(domain: "VoiceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer unavailable"]))
			return
		}

		recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
			if let error = error {
				onError(error)
				self?.stopListening()
				return
			}
			guard let result = result else { return }
			let transcript = result.bestTranscription.formattedString
			if result.isFinal {
				onFinal(transcript)
				self?.stopListening()
			} else {
				onPartial(transcript)
			}
		}
	}

	func stopListening() {
		if audioEngine.isRunning {
			audioEngine.stop()
			audioEngine.inputNode.removeTap(onBus: 0)
		}
		recognitionRequest?.endAudio()
		recognitionTask?.cancel()
		recognitionRequest = nil
		recognitionTask = nil
		isListening = false
	}

	func speak(text: String) {
		guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
		// Do not speak if already speaking
		if isSpeaking { speechSynthesizer.stopSpeaking(at: .immediate) }
		let utterance = AVSpeechUtterance(string: text)
		utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.identifier)
		utterance.rate = AVSpeechUtteranceDefaultSpeechRate
		utterance.pitchMultiplier = 1.0
		utterance.prefersAssistiveTechnologySettings = true
		isSpeaking = true
		speechSynthesizer.speak(utterance)
	}

	func stopSpeaking() {
		speechSynthesizer.stopSpeaking(at: .immediate)
		isSpeaking = false
	}
}

extension VoiceService: AVSpeechSynthesizerDelegate {
	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
		isSpeaking = false
		NotificationCenter.default.post(name: .voiceDidFinishSpeaking, object: nil)
	}
	func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
		isSpeaking = false
		NotificationCenter.default.post(name: .voiceDidFinishSpeaking, object: nil)
	}
}
#else
// Stubs for non-iOS platforms
@MainActor
final class VoiceService {
	private(set) var isListening: Bool = false
	private(set) var isSpeaking: Bool = false
	func startListening(onPartial: @escaping (String) -> Void, onFinal: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {}
	func stopListening() {}
	func speak(text: String) {}
	func stopSpeaking() {}
}
#endif


