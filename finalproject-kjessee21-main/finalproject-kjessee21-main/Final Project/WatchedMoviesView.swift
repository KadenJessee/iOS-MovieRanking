//
//  WatchedMoviesView.swift
//  Final Project
//
//  Created by Kaden Jessee on 7/19/23.
//

import SwiftUI
import MessageUI

struct MovieRankingView: View {
    @Binding var rankedMovies: Set<String>
    @State private var selectedRankedMovie: String = ""
    @State private var isEditModeEnabled = false
    @State private var editedMovieTitle = ""
    let watchedMoviesKey: String
    @StateObject private var messageComposer = MessageComposer()

    var body: some View {
        NavigationView {
            VStack {
                List {
                    if isEditModeEnabled {
                        // Show text fields in edit mode
                        ForEach(rankedMovies.sorted(), id: \.self) { rankedMovie in
                            if rankedMovie == selectedRankedMovie {
                                TextField("Edit Movie", text: $editedMovieTitle)
                            } else {
                                Text("\(rankedMovie)")
                                    .onTapGesture {
                                        selectedRankedMovie = rankedMovie
                                        editedMovieTitle = rankedMovie
                                    }
                            }
                        }
                    } else {
                        // Show buttons when not in edit mode
                        ForEach(rankedMovies.sorted(), id: \.self) { rankedMovie in
                            Text("\(rankedMovie)")
                                .onTapGesture {
                                    selectedRankedMovie = rankedMovie
                                }
                        }
                        .onDelete(perform: deleteRankedMovie)
                    }
                }
                .navigationTitle("Ranked Movies")
                .navigationBarItems(leading: shareButton, trailing: editButton)
            }
        }
        .onChange(of: isEditModeEnabled, perform: { newValue in
            if !newValue && !editedMovieTitle.isEmpty {
                // If we're exiting edit mode and the title was edited, update the rankedMovies set
                if rankedMovies.firstIndex(of: selectedRankedMovie) != nil {
                    rankedMovies.remove(selectedRankedMovie)
                    rankedMovies.insert(editedMovieTitle)
                    saveWatchedMoviesToUserDefaults()
                }
            }
        })
    }

    private var editButton: some View {
        Button(isEditModeEnabled ? "Done" : "Edit") {
            isEditModeEnabled.toggle()
        }
    }

    private var shareButton: some View {
            Button(action: {
                shareRankedMovies()
            }, label: {
                Image(systemName: "square.and.arrow.up")
            })
        }

        private func shareRankedMovies() {
            let rankedMovieList = rankedMovies.sorted().joined(separator: "\n")

            if messageComposer.canSendText {
                messageComposer.body = "My Movies Ranked:\n\(rankedMovieList)"
                messageComposer.present()
            } else {
                // Handle the case when the user's device cannot send text messages
                print("Text messaging is not available.")
            }
        }
    
    private func deleteRankedMovie(at offsets: IndexSet) {
        if let indexToDelete = offsets.first {
            let sortedMovies = rankedMovies.sorted()
            let movieToDelete = sortedMovies[indexToDelete]

            // Create a new array to store the updated ranked movies
            var updatedRankedMovies: [String] = []

            // Variable to keep track of the new rank
            var newRank = 1

            for existingRankedMovie in sortedMovies {
                // Skip the movie to be deleted
                if existingRankedMovie == movieToDelete {
                    continue
                }

                // Recreate the ranked movie with the new rank
                let newRankedMovie = "\(newRank). \(existingRankedMovie.split(separator: ".").dropFirst().joined(separator: "."))"
                updatedRankedMovies.append(newRankedMovie)

                // Increment the rank for the next movie
                newRank += 1
            }

            // Update the rankedMovies set with the updated array
            rankedMovies = Set(updatedRankedMovies)

            // Save the changes to UserDefaults
            saveWatchedMoviesToUserDefaults()
        }
    }


    private func saveWatchedMoviesToUserDefaults() {
        UserDefaults.standard.set(Array(rankedMovies), forKey: watchedMoviesKey)
    }
}

struct MovieRankingView_Previews: PreviewProvider {
    @State static private var rankedMovies: Set<String> = []

    static var previews: some View {
        MovieRankingView(rankedMovies: $rankedMovies, watchedMoviesKey: "")
            .onAppear {
                // Add some sample ranked movies for testing
                rankedMovies = ["4. Movie 1", "2. Movie 2", "3. Movie 3"]
            }
    }
}

class MessageComposer: NSObject, ObservableObject {
    @Published var body: String = ""
    weak var messageComposeDelegate: MFMessageComposeViewControllerDelegate?

    var canSendText: Bool {
        return MFMessageComposeViewController.canSendText()
    }

    func present() {
        if canSendText {
            let messageComposeViewController = MFMessageComposeViewController()
            messageComposeViewController.body = body
            messageComposeViewController.messageComposeDelegate = self
            UIApplication.shared.windows.first?.rootViewController?.present(messageComposeViewController, animated: true, completion: nil)
        }
    }
}

extension MessageComposer: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        // Handle the result of the message sending if needed
        controller.dismiss(animated: true) {
            self.messageComposeDelegate?.messageComposeViewController(controller, didFinishWith: result)
        }
    }
}
