//
//  ContentView.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import FoundationModels
import SwiftUI

struct ContentView: View {
    @State var model = LMModel()
    @State private var showSidebar = false
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity(0.4),
                        Color.yellow.opacity(0.2),
              
                        Color(.systemBackground).opacity(1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(model.session.transcript) { entry in
                            Group {
                                switch entry {
                                case .prompt(let prompt):
                                    MessageView(
                                        segments: prompt.segments,
                                        isUser: true
                                    )
                                    .transition(.offset(y: 500))
                                    .padding(.trailing)

                                case .response(let reponse):
                                    MessageView(
                                        segments: reponse.segments,
                                        isUser: false
                                    )
                                    .padding(.leading, 10)

                                default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .animation(.easeInOut, value: model.session.transcript)

                    if model.isAwaitingResponse {
                        if let last = model.session.transcript.last {
                            if case .prompt = last {
                                Text("Thinking...")
                                    .bold()
                                    .opacity(model.isThinking ? 0.5 : 1)
                                    .padding(.leading)
                                    .offset(y: 15)
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )

                                    .onAppear {
                                        withAnimation(
                                            .linear(duration: 1).repeatForever(
                                                autoreverses: true
                                            )
                                        ) {
                                            model.isThinking.toggle()
                                        }
                                    }
                            }
                        }
                    }
                }
                .defaultScrollAnchor(.bottom, for: .sizeChanges)
                .safeAreaPadding(.bottom, 100)

                HStack {
                    TextField(
                        "Ask me anything...",
                        text: $model.inputText,
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .disabled(model.session.isResponding)
                    .frame(height: 55)
                    .onSubmit {
                        if !model.inputText.isEmpty && !model.session.isResponding {
                            model.sendMessage()
                        }
                    }

                    Button {
                        model.sendMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(
                                model.session.isResponding
                                    ? Color.gray.opacity(0.6) : .primary
                            )
                    }
                    .disabled(
                        model.inputText.isEmpty || model.session.isResponding
                    )
                }
                .padding(.horizontal)
                .glassEffect(.regular.interactive())
                .padding()
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .navigationTitle("Kodiak - Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: CREATE NEW CHAT
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
