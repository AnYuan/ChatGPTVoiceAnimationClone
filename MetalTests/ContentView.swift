//
//  ContentView.swift
//  MetalTests
//
//  Created by Anyuan Dong on 2025/3/6.
//

import SwiftUI


struct ContentView: View {
    var body: some View {
        MetalView()
            .frame(width:300, height: 300)
            .clipShape(.circle)
            .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    ContentView()
}
