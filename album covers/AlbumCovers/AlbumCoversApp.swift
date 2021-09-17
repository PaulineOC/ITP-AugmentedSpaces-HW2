//
//  AlbumCoversApp.swift
//  AlbumCovers
//
//  Created by Nien Lam on 9/15/21.
//  Copyright © 2021 Line Break, LLC. All rights reserved.
//

import SwiftUI

@main
struct AlbumCoversApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: ViewModel())
        }
    }
}
