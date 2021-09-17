//
//  ContentView.swift
//  AlbumCovers
//
//  Created by Nien Lam on 9/15/21.
//  Copyright © 2021 Line Break, LLC. All rights reserved.
//

import SwiftUI


class ViewModel: ObservableObject {
    // Intialize with placeholder information.
    @Published var coverImage: String    = "abbey-road.jpg"
    @Published var albumName: String     = "Abbey Road"
    @Published var artist: String        = "Beatles"
    @Published var currentTrack: String  = "1. Come Together"

    // Indices for current album and track to display.
    var albumIdx: Int = 0
    var trackIdx: Int = 0


    // TODO: Create a stucture for holding album data.
    // coverImage, albumName, artist, tracks
    struct Album {
        let coverImg: String
        let albumName: String
        let artist: String
        var tracks: [String]
       
        init(coverImg: String, albumName: String, artist: String, tracks: [String]){
            self.coverImg = coverImg
            self.albumName = albumName
            self.artist = artist
            self.tracks = tracks
            
            print(self.coverImg)
        }
    }
    
    var allAlbums: [Album] = [];


    init() {
        
        // TODO: Initialize 3 or more albums with data.
        let touristHistory = Album(
            coverImg: "TwoDoorCinema.png",
            albumName: "Tourist History",
            artist: "Two Door Cinema Club",
            tracks: [
                "Cigarettes in the Theatre",
                "Come Back Home",
                "Undercover Martyn",
                "Do You Want It All?",
                "This Is The Life",
                "Something Good Can Work",
                "I Can Talk",
                "What You Know",
                "Eat THat Up, Its Good For You",
                "You're Not Stubborn"
            ]
        );
        
        let backToBlack = Album(
            coverImg: "AmyWinehouse.jpeg",
            albumName: "Back to Black",
            artist: "Amy Winehouse",
            tracks: [
                "Rehab",
                "You Know I'm No Good",
                "Me & Mr. Jones",
                "Just Friends",
                "Back to Black",
                "Love is a Losing Game",
                "Tears Dry On Their Own",
                "Wake Up Alone",
                "Some Unholy War",
                "He Can Only Hold Her",
                "Addicted",
            ]
        );
        
        let ratatouille = Album(
            coverImg: "Ratatouille.jpeg",
            albumName: "Ratatouille (Original Motion Picture Soundtrack)",
            artist: "Michael Giacchino",
            tracks: [
                "Le Festin",
                "Welcome Gusteau's",
                "This Is Me",
                "Granny Get Your Gun",
                "100 Rat Dash",
                "Wall Rat",
                "Cast of Cooks",
                "A Real Gourmet Kitchen",
                "Souped Up",
                "Is It Soup Yet?",
                "A New Deal",
                "Remy Drives a Linguini",
                "Colette Shows Him Le Ropes",
                "Special Order",
                "Kiss & Vinegar",
                "Losing Control",
                "Heist To See You",
                "The Paper Chase",
                "Abandoning Ship",
                "Dinner Rush",
                "Anyone Can Cook",
                "End Creditouilles",
                "Ratatouille Main Theme",
            ]
        );
        
        // TODO: Append albums to array.
        
        allAlbums.append(touristHistory)
        allAlbums.append(backToBlack)
        allAlbums.append(ratatouille)
        
        // TODO: Intialize screen variables with first album.
        // coverImage, albumName, artist, currentTrack
        coverImage = allAlbums[0].coverImg
        albumName = allAlbums[0].albumName
        artist = allAlbums[0].artist
        currentTrack = allAlbums[0].tracks[0]
    }

    // TODO: Update variables: albumIdx, trackIdx, coverImage, albumName, artist, currentTrack
    func nextAlbumButtonPressed() {
        print("🔺 Did press Next Album")
      
        albumIdx += 1
        
        coverImage = allAlbums[albumIdx].coverImg
        albumName = allAlbums[albumIdx].albumName
        artist = allAlbums[albumIdx].artist
        currentTrack = allAlbums[albumIdx].tracks[trackIdx]
       
        if(albumIdx == allAlbums.count-1){
            albumIdx = 0;
            trackIdx = 0 //reset the track since new album
        }
    }

    // TODO: Update variables: trackIdx and currentTrack
    func nextTrackButtonPressed() {
        print("🔺 Did press Next Track")
        
        trackIdx += 1
        coverImage = allAlbums[albumIdx].coverImg
        albumName = allAlbums[albumIdx].albumName
        artist = allAlbums[albumIdx].artist
        currentTrack = allAlbums[albumIdx].tracks[trackIdx]
       
        if(trackIdx ==  allAlbums[albumIdx].tracks.count-1){
            trackIdx = 0 //reset the track since new album
        }
    }
}


struct ContentView: View {
    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack {
            Image(uiImage: UIImage(named: viewModel.coverImage)!)
                .resizable()
                .frame(width: 300, height: 300)
                .padding(.bottom, 10)
            
            Text(viewModel.albumName)
                .font(.system(.title))
            
            Text(viewModel.artist)
                .font(.system(.title2))
                .padding(.bottom, 10)

            Text(viewModel.currentTrack)
                .font(.system(.subheadline))
                .padding(.bottom, 30)
            
            Button {
                viewModel.nextAlbumButtonPressed()
            } label: {
                actionLabel(text: "Next Album", color: .green)
            }
            .padding(.bottom, 15)

            Button {
                viewModel.nextTrackButtonPressed()
            } label: {
                actionLabel(text: "Next Track", color: .orange)
            }
        }
    }

    // Helper method for rendering button label.
    func actionLabel(text: String, color: Color) -> some View {
        Label(text, systemImage: "chevron.forward.square")
            .font(.system(.body))
            .foregroundColor(.white)
            .frame(width: 200, height: 44)
            .background(color)
            .cornerRadius(4)
    }
}
