//
//  MovieDetailView.swift
//  Final Project
//
//  Created by Kaden Jessee on 7/19/23.
//
// MovieDetailView.swift
import SwiftUI

struct MovieDetailView: View {
    @Binding var isPresented: Bool
    @Binding var isWatched: Bool
    @Binding var movie: String
    @Binding var rankedMovies: Set<String>
    @Binding var watchList: [String]
    let watchListKey: String // Add watchListKey parameter
    let watchedMoviesKey: String
    let rankedMoviesCount: Int

    @State private var movieRank: Int = 1

    var body: some View {
            NavigationView {
                VStack {
                    Text(movie)
                        .font(.largeTitle)
                        .padding(.bottom, 20)

                    if isWatched {
                        Stepper("Rank: \(movieRank)", value: $movieRank, in: 1...rankedMoviesCount + 1)
                            .padding(.bottom, 20)
                    }

                    Spacer()

                    HStack {
                        Button("Cancel") {
                            isPresented = false
                        }
                        .frame(width: 75)
                        .padding(.all)

                        Spacer()

                        Button(isWatched ? "Done" : "Mark as Watched") {
                            if isWatched {
                                rankMovie()
                            } else {
                                isWatched = true
                            }
                        }
                        .frame(width: 100)
                        .padding(.all)
                    }
                }
                .padding()
                .navigationTitle("Movie Detail")
            }
        }

        private func rankMovie() {
            let rankedMovie = "\(movieRank). \(movie)"
            if let index = watchList.firstIndex(of: movie) {
                watchList.remove(at: index) // Remove the movie from the watch list
            }

            // Reassign ranks for existing ranked movies that come after the selected rank
            for existingRankedMovie in rankedMovies {
                if let rank = Int(existingRankedMovie.split(separator: ".").first ?? "") {
                    if rank >= movieRank {
                        let newRank = rank + 1
                        let newRankedMovie = "\(newRank). \(existingRankedMovie.split(separator: ".").dropFirst().joined(separator: "."))"
                        rankedMovies.remove(existingRankedMovie)
                        rankedMovies.insert(newRankedMovie)
                    }
                }
            }

            // Add the ranked movie to the set
            rankedMovies.insert(rankedMovie)

            // Save the changes to UserDefaults
            saveWatchedMoviesToUserDefaults()

            isPresented = false
        }

    private func saveWatchedMoviesToUserDefaults() {
        UserDefaults.standard.set(Array(watchList), forKey: watchListKey)
        UserDefaults.standard.set(Array(rankedMovies), forKey: watchedMoviesKey)
    }
}

struct MovieDetailView_Previews: PreviewProvider {
    @State static private var selectedMovie = "Sample Movie"
        @State static private var rankedMovies: Set<String> = []
        @State static private var watchList: [String] = [] // Add watchList as a State variable

        static var previews: some View {
            MovieDetailView(
                isPresented: .constant(true),
                isWatched: .constant(false),
                movie: $selectedMovie,
                rankedMovies: $rankedMovies,
                watchList: $watchList, // Pass the binding to the State variable
                watchListKey: "WatchListKey", // Pass the watchListKey as well
                watchedMoviesKey: "",
                rankedMoviesCount: 1
            )
        }
}
