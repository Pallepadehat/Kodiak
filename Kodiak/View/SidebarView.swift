//
//  SidebarView.swift
//  Kodiak
//
//  Created by Patrick Jakobsen on 11/08/2025.
//

import SwiftUI

struct SidebarView: View {
    var body: some View {
        HStack {
            // Sidebar content
            VStack {
                Text("Sidebar Content")
                Spacer()
            }
            .frame(width: 250)
            .background(Color.white)
            .shadow(radius: 10)

            Spacer()
        }
        .zIndex(1)
        .transition(.move(edge: .leading))
    }
}

#Preview {
    SidebarView()
}
