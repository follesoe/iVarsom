//
//  ContentView.swift
//  iVarsomWatch WatchKit Extension
//
//  Created by Jonas Follesø on 14/04/2022.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            DangerGradient(dangerLevel: .level3)
            VStack {
                DangerIcon(dangerLevel: .level3)
                    .padding()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
