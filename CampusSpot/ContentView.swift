import SwiftUI
import ParseSwift

// MARK: - Main Content View
struct ContentView: View {
    @AppStorage("campusSpotIsLoggedIn") private var isLoggedIn = false
    @State private var currentScreen = "welcome"

    var body: some View {
        NavigationStack {
            Group {
                switch currentScreen {
                case "welcome":
                    WelcomeView {
                        currentScreen = "login"
                    }

                case "login":
                    LoginView(
                        onSignUp: {
                            currentScreen = "signup"
                        },
                        onBack: {
                            currentScreen = "welcome"
                        },
                        onLogin: {
                            isLoggedIn = true
                            currentScreen = "home"
                        }
                    )

                case "signup":
                    SignUpView(
                        onLogin: {
                            currentScreen = "login"
                        },
                        onBack: {
                            currentScreen = "login"
                        },
                        onSignedUp: {
                            isLoggedIn = true
                            currentScreen = "home"
                        }
                    )

                case "home":
                    MainTabView(onLogout: {
                        Task {
                            try? await User.logout()
                            await MainActor.run {
                                isLoggedIn = false
                                currentScreen = "login"
                            }
                        }
                    })

                default:
                    WelcomeView {
                        currentScreen = "login"
                    }
                }
            }
            .animation(.easeInOut, value: currentScreen)
        }
        .onAppear {
            let authenticated = User.current != nil || isLoggedIn
            isLoggedIn = authenticated
            currentScreen = authenticated ? "home" : "welcome"
        }
    }
}

// MARK: - CampusSpot Header

struct CampusSpotHeader: View {
    var showBackButton = false
    var onBack: (() -> Void)?

    var body: some View {
        HStack {
            if showBackButton {
                Button(action: {
                    onBack?()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                        Text("CampusSpot")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                }
            } else {
                Text("CampusSpot")
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

// MARK: - Welcome Screen

struct WelcomeView: View {
    var onGetStarted: () -> Void

    var body: some View {
        VStack {
            CampusSpotHeader()

            Spacer()

            VStack(spacing: 12) {
                Text("Campus")
                    .font(.system(size: 38, weight: .medium))

                Text("Spot")
                    .font(.system(size: 38, weight: .medium))
            }

            Spacer()

            VStack(spacing: 20) {
                Text("Welcome!")
                    .font(.title3)
                    .fontWeight(.medium)

                Button(action: onGetStarted) {
                    Text("Get started")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 35)
        }
    }
}

// MARK: - Login Screen

struct LoginView: View {
    var onSignUp: () -> Void
    var onBack: () -> Void
    var onLogin: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showForgotPassword = false
    @State private var showLoginError = false

    var body: some View {
        VStack(spacing: 0) {
            CampusSpotHeader(showBackButton: true, onBack: onBack)

            Text("Log in")
                .font(.title2)
                .fontWeight(.medium)
                .padding(.top, 35)

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("Email")
                        .font(.caption)

                    TextField("University email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }

                VStack(alignment: .leading, spacing: 7) {
                    Text("Password")
                        .font(.caption)

                    SecureField("Enter password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }

                HStack {
                    Spacer()

                    Button("Forgot password?") {
                        showForgotPassword = true
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Button(action: performLogin) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Log in")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .disabled(isLoading)
                .padding(.top, 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 45)

            Spacer()

            VStack(spacing: 12) {
                Text("Don't have an account?")
                    .font(.caption)

                Button(action: onSignUp) {
                    Text("Sign up")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay {
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.secondary, lineWidth: 1)
                        }
                }
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 45)
        }
        .alert("Forgot Password", isPresented: $showForgotPassword) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Password recovery will be connected to your account.")
        }
        .alert("Login Failed", isPresented: $showLoginError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage.isEmpty ? "Please check your email and password." : errorMessage)
        }
    }

    private func performLogin() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter your email and password."
            showLoginError = true
            return
        }

        isLoading = true
        Task {
            do {
                _ = try await User.login(username: trimmedEmail, password: password)
                await MainActor.run {
                    isLoading = false
                    onLogin()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showLoginError = true
                }
            }
        }
    }
}

// MARK: - Sign Up Screen

struct SignUpView: View {
    var onLogin: () -> Void
    var onBack: () -> Void
    var onSignedUp: (() -> Void)? = nil

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var showSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            CampusSpotHeader(showBackButton: true, onBack: onBack)

            Text("Sign up")
                .font(.title2)
                .fontWeight(.medium)
                .padding(.top, 25)

            VStack(alignment: .leading, spacing: 16) {
                inputField(
                    title: "Name",
                    placeholder: "Full name",
                    text: $fullName
                )

                inputField(
                    title: "Email",
                    placeholder: "University email",
                    text: $email,
                    email: true
                )

                inputField(
                    title: "Password",
                    placeholder: "Create password",
                    text: $password,
                    secure: true
                )

                inputField(
                    title: "Confirm password",
                    placeholder: "Re-enter password",
                    text: $confirmPassword,
                    secure: true
                )

                Button(action: performSignUp) {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Create account")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .background(Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
                .disabled(isLoading)
                .padding(.top, 5)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)

            Spacer()

            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(.secondary)

                Button("Log in", action: onLogin)
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .padding(.bottom, 40)
        }
        .alert("Sign Up Failed", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage.isEmpty ? "Could not create account." : errorMessage)
        }
        .alert("Account Created", isPresented: $showSuccess) {
            Button("Continue") {
                if let onSignedUp {
                    onSignedUp()
                } else {
                    onLogin()
                }
            }
        } message: {
            Text("Your account is ready.")
        }
    }

    private func performSignUp() {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            showError = true
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            showError = true
            return
        }

        isLoading = true
        var newUser = User()
        newUser.username = trimmedEmail
        newUser.email = trimmedEmail
        newUser.password = password
        newUser.fullName = trimmedName

        Task {
            do {
                _ = try await newUser.signup()
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }

    @ViewBuilder
    private func inputField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        email: Bool = false,
        secure: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.caption)

            Group {
                if secure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(email ? .emailAddress : .default)
                        .textInputAutocapitalization(email ? .never : .words)
                        .autocorrectionDisabled(email)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
    }
}

// MARK: - Campus and Study Spot Data

enum Campus: String, CaseIterable, Identifiable {
    case mmc = "Modesto A. Maidique Campus"
    case bbc = "Biscayne Bay Campus"
    case engineering = "Engineering Center"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .mmc: return "MMC"
        case .bbc: return "BBC"
        case .engineering: return "EC"
        }
    }

    var symbol: String {
        switch self {
        case .mmc: return "building.2"
        case .bbc: return "water.waves"
        case .engineering: return "gearshape.2"
        }
    }
}

struct StudySpot: Identifiable {
    let id: String
    let name: String
    let campus: Campus
    let description: String
    let environment: String
    var noiseLevel: String? = nil
    var hasOutlets: Bool? = nil
    var averageRating: Double? = nil
    var imageName: String? = nil

    init(
        id: String = UUID().uuidString,
        name: String,
        campus: Campus,
        description: String,
        environment: String,
        noiseLevel: String? = nil,
        hasOutlets: Bool? = nil,
        averageRating: Double? = nil,
        imageName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.campus = campus
        self.description = description
        self.environment = environment
        self.noiseLevel = noiseLevel
        self.hasOutlets = hasOutlets
        self.averageRating = averageRating
        self.imageName = imageName
    }
}

let studySpots: [StudySpot] = [
    // MMC

    StudySpot(
        id: "green-library",
        name: "Steven and Dorothea Green Library",
        campus: .mmc,
        description: "Main library with computer labs, seating, quiet floors, and reservable study rooms.",
        environment: "Quiet and Collaborative",
        imageName: "GreenLibrary"
    ),
    StudySpot(
        id: "marc-building",
        name: "MARC Building",
        campus: .mmc,
        description: "Popular study areas near the entrance and on the third floor.",
        environment: "Quiet",
        imageName: "MARC"
    ),
    StudySpot(
        id: "innovation-hub",
        name: "FIU Innovation Hub",
        campus: .mmc,
        description: "Flexible study space with high-top tables, cubicles, couches, and whiteboards.",
        environment: "Collaborative",
        imageName: "InnovationHub"
    ),
    StudySpot(
        id: "deuxieme-maison",
        name: "Deuxieme Maison Sky Lounge",
        campus: .mmc,
        description: "Open-air courtyard with a relaxed atmosphere.",
        environment: "Outdoor",
        imageName: "DeuxiemeMaison"
    ),
    StudySpot(
        id: "mango-building",
        name: "MANGO Building",
        campus: .mmc,
        description: "Academic building with study and academic spaces across six stories.",
        environment: "Indoor",
        imageName: "MANGO"
    ),
    StudySpot(
        id: "graham-center",
        name: "Graham Center",
        campus: .mmc,
        description: "Student center with social areas, food options, and quieter corners.",
        environment: "Social and Collaborative",
        imageName: "GrahamCenter"
    ),
    StudySpot(
        id: "barnes-noble",
        name: "Barnes & Noble at FIU",
        campus: .mmc,
        description: "Seating areas and a second-floor cafe.",
        environment: "Relaxed",
        imageName: "BarnesNoble"
    ),
    StudySpot(
        id: "chemistry-physics",
        name: "Chemistry and Physics Building",
        campus: .mmc,
        description: "Covered outdoor benches with roofs and solar-powered outlets.",
        environment: "Outdoor",
        imageName: "ChemistryPhysics"
    ),
    StudySpot(
        id: "green-lake",
        name: "Green Lake and Campus Courtyards",
        campus: .mmc,
        description: "Outdoor benches and courtyard seating around Green Lake and campus.",
        environment: "Outdoor",
        imageName: "GreenLake"
    ),
    StudySpot(
        id: "chilis-patio",
        name: "Chili's Outdoor Patio",
        campus: .mmc,
        description: "Outdoor patio overlooking the lake and fountain.",
        environment: "Social and Outdoor",
        imageName: "Chilis"
    ),

    // BBC

    StudySpot(
        id: "hubert-library",
        name: "Hubert Library",
        campus: .bbc,
        description: "Main library with seating, computer labs, quiet zones, and reservable rooms.",
        environment: "Quiet and Collaborative",
        imageName: "HubertLibrary"
    ),
    StudySpot(
        id: "academic-center-2",
        name: "Academic Center 2",
        campus: .bbc,
        description: "Second-floor shaded benches for studying and group work.",
        environment: "Outdoor and Collaborative",
        imageName: "AcademicCenter2"
    ),
    StudySpot(
        id: "wolfe-center",
        name: "Wolfe University Center",
        campus: .bbc,
        description: "Second and third-floor patios with tables, benches, couches, and student areas.",
        environment: "Social and Collaborative",
        imageName: "WolfeCenter"
    ),
    StudySpot(
        id: "marine-science",
        name: "By the Bay / Marine Science Area",
        campus: .bbc,
        description: "Outdoor study areas near the water with bay views.",
        environment: "Outdoor and Quiet",
        imageName: "MarineScience"
    ),
    StudySpot(
        id: "aquatic-center",
        name: "Aquatic Center Swinging Benches",
        campus: .bbc,
        description: "Scenic swinging benches near the water.",
        environment: "Outdoor",
        imageName: "AquaticCenter"
    ),

    // Engineering Center

    StudySpot(
        id: "engineering-library",
        name: "Engineering Library Services (EC-2780)",
        campus: .engineering,
        description: "Second-floor study space with quiet seating, group rooms, printing, and device checkouts.",
        environment: "Quiet and Collaborative",
        imageName: "EngineeringLibrary"
    ),
    StudySpot(
        id: "engineering-labs",
        name: "Engineering Information Center and Labs",
        campus: .engineering,
        description: "Specialized labs and group study areas. Some rooms require advance reservations.",
        environment: "Academic and Collaborative",
        imageName: "EngineeringLabs"
    )
]

// MARK: - Main Tab Navigation

struct MainTabView: View {
    var onLogout: () -> Void

    @State private var locations: [Location] = []
    @State private var isLoadingLocations = false

    private var spots: [StudySpot] {
        studySpots
    }

    var body: some View {
        TabView {
            HomeView(spots: spots, isLoading: isLoadingLocations, onRefresh: loadLocations)
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            SearchView(spots: spots, onRefresh: loadLocations)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            BookmarksView()
                .tabItem {
                    Label("Bookmarks", systemImage: "bookmark")
                }

            ProfileView(onLogout: onLogout)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
            
            
        }
        .tint(.accentColor)
        .task {
            if locations.isEmpty {
                await loadLocations()
            }
        }
    }

    private func loadLocations() async {
        isLoadingLocations = true
        defer { isLoadingLocations = false }
        do {
            locations = try await BackendService.fetchLocations()
        } catch {
            print("Failed to fetch locations: \(error.localizedDescription)")
        }
    }
}

// MARK: - Home Feed

struct HomeView: View {
    let spots: [StudySpot]
    var isLoading: Bool = false
    var onRefresh: (() async -> Void)? = nil

    private var featuredSpot: StudySpot {
        spots.first ?? studySpots[0]
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    CampusSpotHeader()

                    if isLoading && spots.isEmpty {
                        ProgressView("Loading study spots...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Featured Study Spot")
                            .font(.title2)
                            .fontWeight(.semibold)

                        NavigationLink(destination: StudySpotDetailView(spot: featuredSpot)) {
                            VStack(alignment: .leading, spacing: 10) {
                                ZStack(alignment: .bottomLeading) {
                                    if let imageName = featuredSpot.imageName {
                                        Image(imageName)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(height: 190)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.12))
                                            .frame(height: 190)

                                        Image(systemName: "books.vertical.fill")
                                            .font(.system(size: 65))
                                            .foregroundStyle(.blue.opacity(0.7))
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }

                                    Text(featuredSpot.campus.shortName)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.regularMaterial)
                                        .clipShape(Capsule())
                                        .padding(12)
                                }

                                Text(featuredSpot.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text(featuredSpot.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Label(featuredSpot.environment, systemImage: "book")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Browse by Campus")
                            .font(.title2)
                            .fontWeight(.semibold)

                        ForEach(Campus.allCases) { campus in
                            let campusSpots = spots.filter { $0.campus == campus }
                            NavigationLink(
                                destination: CampusLocationsView(campus: campus, spots: campusSpots)
                            ) {
                                HStack(spacing: 15) {
                                    Image(campus.rawValue == "Modesto A. Maidique Campus" ? "MMC" : campus.rawValue == "Biscayne Bay Campus" ? "BBC" : "Engineering")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 55, height: 55)
                                        .clipped()
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(campus.rawValue)
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Text("\(campusSpots.count) study spots")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 25)
            }
            .refreshable {
                await onRefresh?()
            }
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Campus Locations Screen

struct CampusLocationsView: View {
    let campus: Campus
    let spots: [StudySpot]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(campus.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 10)

                Text("Explore study spots at this campus.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(spots) { spot in
                    NavigationLink(destination: StudySpotDetailView(spot: spot)) {
                        StudySpotRow(spot: spot)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle(campus.shortName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Search Screen

struct SearchView: View {
    let spots: [StudySpot]
    var onRefresh: (() async -> Void)? = nil

    @State private var searchText = ""

    private var filteredSpots: [StudySpot] {
        if searchText.isEmpty {
            return spots
        }

        return spots.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText) ||
            $0.campus.rawValue.localizedCaseInsensitiveContains(searchText) ||
            ($0.noiseLevel?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CampusSpotHeader()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Explore Study Spots")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Browse locations across all FIU campuses.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    TextField("Search study spots...", text: $searchText)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Text("\(filteredSpots.count) study spots")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()

                List(filteredSpots) { spot in
                    NavigationLink(destination: StudySpotDetailView(spot: spot)) {
                        StudySpotRow(spot: spot)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await onRefresh?()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Study Spot Row

struct StudySpotRow: View {
    let spot: StudySpot

    var body: some View {
        HStack(spacing: 14) {
            if let imageName = spot.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 55, height: 55)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 55, height: 55)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(spot.name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(spot.campus.shortName)
                    .font(.caption)
                    .foregroundStyle(.blue)

                Text(spot.environment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 5)
    }
}


// MARK: - Study Spot Detail

struct StudySpotDetailView: View {

    let spot: StudySpot

    // Bookmark
    @State private var isBookmarked = false
    @State private var isLoadingBookmark = false
    @State private var bookmarkError = ""

    // Reviews
    @State private var reviews: [Review] = []
    @State private var selectedRating = 5
    @State private var reviewComment = ""
    @State private var isLoadingReviews = false
    @State private var isSubmittingReview = false
    @State private var reviewError = ""
    @State private var reviewMessage = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                // Study Spot Image
                ZStack {
                    if let imageName = spot.imageName {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.12))
                            .frame(height: 200)

                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 65))
                            .foregroundStyle(.blue)
                    }
                }

                // Study Spot Name
                Text(spot.name)
                    .font(.title2)
                    .fontWeight(.bold)

                // Bookmark Button
                HStack {
                    Text("Save this study spot")
                        .font(.subheadline)

                    Spacer()

                    Button {
                        Task {
                            await toggleBookmark()
                        }
                    } label: {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.title2)
                    }
                    .disabled(isLoadingBookmark)
                }
                .padding(.vertical, 8)

                // Campus
                Label(spot.campus.rawValue, systemImage: "building.2")
                    .foregroundStyle(.secondary)

                // About
                Text("About this spot")
                    .font(.headline)

                Text(spot.description)
                    .foregroundStyle(.secondary)

                // Environment
                Text("Study Environment")
                    .font(.headline)

                Text(spot.environment)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Capsule())

                Divider()

                // MARK: - Write a Review

                Text("Leave a Review")
                    .font(.headline)

                Text("How would you rate this study spot?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Star Rating Selector
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { rating in
                        Button {
                            selectedRating = rating
                        } label: {
                            Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundStyle(.yellow)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Review Comment
                TextField("Write your review...", text: $reviewComment, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Submit Button
                Button {
                    Task {
                        await submitReview()
                    }
                } label: {
                    HStack {
                        if isSubmittingReview {
                            ProgressView()
                                .tint(.white)
                        }

                        Text(isSubmittingReview ? "Submitting..." : "Submit Review")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(isSubmittingReview || reviewComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !reviewError.isEmpty {
                    Text(reviewError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                if !reviewMessage.isEmpty {
                    Text(reviewMessage)
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Divider()

                // MARK: - Existing Reviews

                Text("Reviews")
                    .font(.headline)

                if isLoadingReviews {
                    ProgressView("Loading reviews...")
                        .frame(maxWidth: .infinity)
                } else if reviews.isEmpty {
                    Text("No reviews yet. Be the first to review this spot!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(reviews.indices, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {

                            HStack {
                                HStack(spacing: 3) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= (reviews[index].rating ?? 0) ? "star.fill" : "star")
                                            .foregroundStyle(.yellow)
                                    }
                                }

                                Spacer()

                                if let date = reviews[index].createdAt {
                                    Text(date, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            if let comment = reviews[index].comment {
                                Text(comment)
                                    .font(.subheadline)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Study Spot")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadBookmarkStatus()
            await loadReviews()
        }
    }

    // MARK: - Bookmark Functions

    private func loadBookmarkStatus() async {
        do {
            isBookmarked = try await BackendService.isBookmarked(spotId: spot.id)
        } catch {
            print("Failed to load bookmark status: \(error.localizedDescription)")
        }
    }

    private func toggleBookmark() async {
        guard !isLoadingBookmark else { return }

        isLoadingBookmark = true
        defer { isLoadingBookmark = false }

        do {
            let result = try await BackendService.toggleBookmark(for: spot.id)
            isBookmarked = result
            bookmarkError = ""
        } catch {
            bookmarkError = error.localizedDescription
            print("Bookmark error: \(error.localizedDescription)")
        }
    }

    // MARK: - Review Functions

    private func loadReviews() async {
        isLoadingReviews = true
        defer { isLoadingReviews = false }

        do {
            reviews = try await BackendService.fetchReviews(for: spot.id)
        } catch {
            reviewError = "Could not load reviews."
            print("Review loading error: \(error.localizedDescription)")
        }
    }

    private func submitReview() async {
        guard !isSubmittingReview else { return }

        let comment = reviewComment.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !comment.isEmpty else {
            reviewError = "Please write a comment before submitting."
            return
        }

        isSubmittingReview = true
        reviewError = ""
        reviewMessage = ""

        defer { isSubmittingReview = false }

        do {
            let newReview = try await BackendService.submitReview(
                for: spot.id,
                rating: selectedRating,
                comment: comment
            )

            reviews.insert(newReview, at: 0)
            reviewComment = ""
            selectedRating = 5
            reviewMessage = "Your review was submitted successfully!"

        } catch {
            reviewError = "Could not submit your review. Please try again."
            print("Review submission error: \(error.localizedDescription)")
        }
    }
}


// MARK: - Bookmarks Tab

struct BookmarksView: View {
    @State private var savedSpots: [StudySpot] = []
    @State private var isLoading = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 15) {
                CampusSpotHeader()

                Text("Your Bookmarks")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.horizontal)

                if isLoading {
                    Spacer()
                    ProgressView("Loading bookmarks...")
                    Spacer()
                } else if !errorMessage.isEmpty {
                    Spacer()
                    Text(errorMessage)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                    Spacer()
                } else if savedSpots.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 45))
                            .foregroundStyle(.secondary)

                        Text("No bookmarks yet")
                            .font(.headline)

                        Text("Save your favorite study spots to find them here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                } else {
                    List(savedSpots) { spot in
                        NavigationLink(
                            destination: StudySpotDetailView(spot: spot)
                        ) {
                            StudySpotRow(spot: spot)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await loadBookmarks()
            }
            .refreshable {
                await loadBookmarks()
            }
        }
    }

    private func loadBookmarks() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }

        do {
            let bookmarks = try await BackendService.fetchUserBookmarks()
            let savedIDs = Set(bookmarks.compactMap { $0.spotId })

            savedSpots = studySpots.filter {
                savedIDs.contains($0.id)
            }
        } catch {
            errorMessage = error.localizedDescription
            print("Failed to load bookmarks: \(error.localizedDescription)")
        }
    }
}


// MARK: - Profile Tab

struct ProfileView: View {

   var onLogout: () -> Void

   @State private var displayName = ""
   @State private var email = ""
   @State private var bookmarkCount = 0
   @State private var reviewCount = 0
   @State private var userReviews: [Review] = []
   @State private var isLoading = true
   @State private var errorMessage = ""

   var body: some View {

       NavigationStack {

           ScrollView {

               VStack(alignment: .leading, spacing: 20) {

                   CampusSpotHeader()

                   // Profile Information
                   VStack(spacing: 10) {

                       Image(systemName: "person.crop.circle.fill")
                           .font(.system(size: 75))
                           .foregroundStyle(.blue)

                       Text(displayName.isEmpty ? "CampusSpot User" : displayName)
                           .font(.title2)
                           .fontWeight(.bold)

                       Text(email)
                           .font(.subheadline)
                           .foregroundStyle(.secondary)
                   }
                   .frame(maxWidth: .infinity)
                   .padding(.vertical, 20)

                   // Account Statistics
                   HStack(spacing: 12) {

                       StatCard(
                           title: "Bookmarks",
                           count: bookmarkCount,
                           icon: "bookmark.fill"
                       )

                       StatCard(
                           title: "Reviews",
                           count: reviewCount,
                           icon: "star.fill"
                       )
                   }

                   Divider()

                   // User Reviews
                   Text("My Reviews")
                       .font(.headline)

                   if isLoading {

                       ProgressView("Loading profile...")
                           .frame(maxWidth: .infinity)

                   } else if !errorMessage.isEmpty {

                       Text(errorMessage)
                           .foregroundStyle(.secondary)

                   } else if userReviews.isEmpty {

                       Text("You haven't submitted any reviews yet.")
                           .font(.subheadline)
                           .foregroundStyle(.secondary)

                   } else {

                       ForEach(userReviews.indices, id: \.self) { index in

                           let review = userReviews[index]
                           let spotName = studySpots.first {
                               $0.id == review.spotId
                           }?.name ?? "Study Spot"

                           VStack(alignment: .leading, spacing: 8) {

                               Text(spotName)
                                   .font(.subheadline)
                                   .fontWeight(.semibold)

                               HStack(spacing: 3) {
                                   ForEach(1...5, id: \.self) { star in
                                       Image(
                                           systemName: star <= (review.rating ?? 0)
                                           ? "star.fill"
                                           : "star"
                                       )
                                       .foregroundStyle(.yellow)
                                   }
                               }

                               Text(review.comment ?? "")
                                   .font(.subheadline)
                                   .foregroundStyle(.secondary)

                               if let date = review.createdAt {
                                   Text(date, style: .date)
                                       .font(.caption)
                                       .foregroundStyle(.secondary)
                               }
                           }
                           .padding()
                           .frame(maxWidth: .infinity, alignment: .leading)
                           .background(Color(.secondarySystemBackground))
                           .clipShape(RoundedRectangle(cornerRadius: 12))
                       }
                   }

                   // Log Out
                   Button("Log Out", role: .destructive) {
                       onLogout()
                   }
                   .frame(maxWidth: .infinity)
                   .padding(.top, 15)
               }
               .padding()
           }
           .toolbar(.hidden, for: .navigationBar)
           .task {
               await loadProfile()
           }
           .refreshable {
               await loadProfile()
           }
       }
   }

   // MARK: - Load Profile Data

   private func loadProfile() async {

       isLoading = true
       errorMessage = ""

       defer {
           isLoading = false
       }

       displayName = BackendService.currentUserDisplayName()
       email = BackendService.currentUserEmail()

       do {
           async let bookmarks = BackendService.fetchUserBookmarks()
           async let reviews = BackendService.fetchUserReviews()

           let loadedBookmarks = try await bookmarks
           let loadedReviews = try await reviews

           bookmarkCount = loadedBookmarks.count
           userReviews = loadedReviews
           reviewCount = loadedReviews.count

       } catch {
           errorMessage = "Unable to load your profile information."
           print("Profile loading error: \(error.localizedDescription)")
       }
   }
}

// MARK: - Profile Stat Card

struct StatCard: View {

   let title: String
   let count: Int
   let icon: String

   var body: some View {

       VStack(spacing: 8) {

           Image(systemName: icon)
               .font(.title2)
               .foregroundStyle(.blue)

           Text("\(count)")
               .font(.title2)
               .fontWeight(.bold)

           Text(title)
               .font(.caption)
               .foregroundStyle(.secondary)
       }
       .frame(maxWidth: .infinity)
       .padding()
       .background(Color(.secondarySystemBackground))
       .clipShape(RoundedRectangle(cornerRadius: 12))
   }
}

// MARK: - Preview

#Preview {
    ContentView()
}
