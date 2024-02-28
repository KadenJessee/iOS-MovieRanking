//
//  ContentView.swift
//  Final Project
//
//  Created by Kaden Jessee on 7/19/23.
//
// ContentView.swift
import SwiftUI
import SQLite3

struct ContentView: View {
    @State private var movieTitle = ""
    @State private var watchList: [String] = []
    @State private var watchedMovies: Set<String> = []
    @State private var isPresentingMovieDetail = false
    @State private var selectedMovie: String = ""
    @State private var activeTab = 0
    @State private var rankedMovies: Set<String> = []
    @State private var isMovieWatched = false
    var rankedMoviesCount: Int{
        rankedMovies.count
    }

    private let watchListKey = "WatchListKey"
    private let watchedMoviesKey = "WatchedMoviesKey"

    // SQLite3 Database Manager
    private let databaseManager = DatabaseManager.shared

    var body: some View {
        TabView(selection: $activeTab) {
            NavigationView {
                VStack {
                    List {
                        Section(header: Text("Add a Movie")) {
                            TextField("Enter movie title", text: $movieTitle)
                            Button("Add to Watch List") {
                                addMovieToWatchList()
                            }
                        }
                        Section(header: Text("Watch List")) {
                            ForEach(watchList, id: \.self) { movie in
                                Button(action: {
                                    selectedMovie = movie
                                    isPresentingMovieDetail = true
                                }) {
                                    HStack {
                                        Text(movie)
                                        Spacer()
                                        if watchedMovies.contains(movie) {
                                            Text("Marked as watched")
                                        } else {
                                            Text("Not Watched")
                                        }
                                    }
                                }
                            }
                            .onDelete(perform: deleteMovie)
                        }
                    }
                    .listStyle(GroupedListStyle())
                }
                .sheet(isPresented: $isPresentingMovieDetail, onDismiss: {
                    if isMovieWatched {
                        presentMovieRankingView()
                    }
                }) {
                    MovieDetailView(
                        isPresented: $isPresentingMovieDetail,
                        isWatched: $isMovieWatched,
                        movie: $selectedMovie,
                        rankedMovies: $rankedMovies,
                        watchList: $watchList,
                        watchListKey: watchListKey, // Pass watchListKey to MovieDetailView
                        watchedMoviesKey: watchedMoviesKey,
                        rankedMoviesCount: rankedMoviesCount
                    )
                }
                .navigationTitle("Movie Watch List")
                .onAppear(perform: {
                    // Load data from SQLite3 Database
                    loadWatchListFromDatabase()
                    loadRankedMoviesFromDatabase()
                })
            }
            .tabItem {
                Label("Watch List", systemImage: "list.bullet")
            }
            .tag(0)

            MovieRankingView(rankedMovies: $rankedMovies, watchedMoviesKey: watchedMoviesKey)
                .tabItem {
                    Label("Ranked Movies", systemImage: "star")
                }
                .tag(1)
        }
        .onChange(of: activeTab, perform: { _ in
            // Save data to SQLite3 Database when tab changes
            saveWatchListToDatabase()
            saveRankedMoviesToDatabase()
        })
    }

    private func addMovieToWatchList() {
        guard !movieTitle.isEmpty else { return }
        watchList.append(movieTitle)
        movieTitle = ""
        saveWatchListToUserDefaults()
    }

    private func deleteMovie(at offsets: IndexSet) {
        watchList.remove(atOffsets: offsets)
        saveWatchListToUserDefaults()
    }

    private func saveWatchListToUserDefaults() {
        UserDefaults.standard.set(watchList, forKey: watchListKey)
    }

    private func presentMovieRankingView() {
            isPresentingMovieDetail = false

            if let index = watchList.firstIndex(of: selectedMovie) {
                watchList.remove(at: index)
                if isMovieWatched {
                    rankedMovies.insert(selectedMovie)
                    updateRanksAfterInsertion(rank: rankedMovies.count)
                    saveWatchedMoviesToUserDefaults()
                }
                saveWatchListToUserDefaults()
            }
            activeTab = 1
        }

        private func updateRanksAfterInsertion(rank: Int) {
            var updatedRankedMovies: Set<String> = []
            for existingRankedMovie in rankedMovies {
                if let existingRank = Int(existingRankedMovie.split(separator: ".").first ?? "") {
                    if existingRank >= rank {
                        let newRank = existingRank + 1
                        let newRankedMovie = "\(newRank). \(existingRankedMovie.split(separator: ".").dropFirst().joined(separator: "."))"
                        updatedRankedMovies.insert(newRankedMovie)
                    } else {
                        updatedRankedMovies.insert(existingRankedMovie)
                    }
                }
            }
            rankedMovies = updatedRankedMovies
        }



    private func saveWatchedMoviesToUserDefaults() {
        UserDefaults.standard.set(Array(watchedMovies), forKey: watchedMoviesKey)
    }

    init() {
        if let savedWatchedMovies = UserDefaults.standard.stringArray(forKey: watchedMoviesKey) {
            watchedMovies = Set(savedWatchedMovies)
        }
        if let savedWatchList = UserDefaults.standard.stringArray(forKey: watchListKey) {
            watchList = savedWatchList
        }
    }
    
    // MARK: - SQLite3 Database Operations

        private func loadWatchListFromDatabase() {
            if let watchListFromDB = databaseManager.fetchWatchList() {
                watchList = watchListFromDB
            }
        }

        private func saveWatchListToDatabase() {
            databaseManager.deleteAllWatchList()
            for movie in watchList {
                databaseManager.insertMovieToWatchList(movie: movie)
            }
        }

        private func loadRankedMoviesFromDatabase() {
            if let rankedMoviesFromDB = databaseManager.fetchRankedMovies() {
                rankedMovies = rankedMoviesFromDB
            }
        }

        private func saveRankedMoviesToDatabase() {
            databaseManager.deleteAllRankedMovies()
            for (index, movie) in rankedMovies.sorted().enumerated() {
                databaseManager.insertRankedMovie(movie: movie, rank: index + 1)
            }
        }
    
}
// MARK: - SQLite3 Database Manager

class DatabaseManager {
    static let shared = DatabaseManager()
    private var database: OpaquePointer?

    private init() {
        openDatabase()
        createTables()
    }

    private func openDatabase() {
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("MovieDatabase.sqlite")

        if sqlite3_open(fileURL.path, &database) != SQLITE_OK {
            print("Error opening database")
        }
    }

    private func createTables() {
        let createWatchListTableQuery = """
            CREATE TABLE IF NOT EXISTS WatchList(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                movie VARCHAR
            );
            """

        let createRankedMoviesTableQuery = """
            CREATE TABLE IF NOT EXISTS RankedMovies(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                movie VARCHAR,
                rank INTEGER
            );
            """

        if sqlite3_exec(database, createWatchListTableQuery, nil, nil, nil) != SQLITE_OK {
            print("Error creating WatchList table")
        }

        if sqlite3_exec(database, createRankedMoviesTableQuery, nil, nil, nil) != SQLITE_OK {
            print("Error creating RankedMovies table")
        }
    }

    func insertMovieToWatchList(movie: String) {
        let insertQuery = """
            INSERT INTO WatchList (movie)
            VALUES (?);
            """

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(database, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (movie as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting movie to WatchList")
            }
        }
        sqlite3_finalize(statement)
    }

    func deleteAllWatchList() {
        let deleteQuery = "DELETE FROM WatchList;"

        if sqlite3_exec(database, deleteQuery, nil, nil, nil) != SQLITE_OK {
            print("Error deleting WatchList")
        }
    }

    func fetchWatchList() -> [String]? {
        let selectQuery = "SELECT movie FROM WatchList;"
        var watchList: [String] = []

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(database, selectQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let movie = String(cString: sqlite3_column_text(statement, 0))
                watchList.append(movie)
            }
        }

        sqlite3_finalize(statement)

        return watchList.isEmpty ? nil : watchList
    }

    func insertRankedMovie(movie: String, rank: Int) {
        let insertQuery = """
            INSERT INTO RankedMovies (movie, rank)
            VALUES (?, ?);
            """

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(database, insertQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (movie as NSString).utf8String, -1, nil)
            sqlite3_bind_int(statement, 2, Int32(rank))

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error inserting ranked movie")
            }
        }
        sqlite3_finalize(statement)
    }

    func deleteAllRankedMovies() {
        let deleteQuery = "DELETE FROM RankedMovies;"

        if sqlite3_exec(database, deleteQuery, nil, nil, nil) != SQLITE_OK {
            print("Error deleting RankedMovies")
        }
    }

    func fetchRankedMovies() -> Set<String>? {
        let selectQuery = "SELECT movie, rank FROM RankedMovies ORDER BY rank ASC;"
        var rankedMovies: Set<String> = []

        var statement: OpaquePointer?

        if sqlite3_prepare_v2(database, selectQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let movie = String(cString: sqlite3_column_text(statement, 0))
                rankedMovies.insert(movie)
            }
        }

        sqlite3_finalize(statement)

        return rankedMovies.isEmpty ? nil : rankedMovies
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
