//
//  BackendService.swift
//  CampusSpot
//
//  Created by amanda torres on 11/22/26.
//

import Foundation
import ParseSwift

enum BackendServiceError: LocalizedError {
    case notAuthenticated
    case missingObjectId

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .missingObjectId:
            return "The record is missing an objectId from Back4App."
        }
    }
}

enum BackendService {

    //  Locations

    static func fetchLocations() async throws -> [Location] {
        let query = Location.query()
            .order([.ascending("name")])
        return try await query.find()
    }

    //  Bookmarks

    static func fetchUserBookmarks() async throws -> [Bookmark] {
        guard let currentUser = User.current else {
            throw BackendServiceError.notAuthenticated
        }
        let userPointer = try currentUser.toPointer()
        let query = Bookmark.query("user" == userPointer)
            .include(["location"])
            .order([.descending("createdAt")])
        return try await query.find()
    }

    static func isBookmarked(location: Location) async throws -> Bool {
        guard let currentUser = User.current else {
            return false
        }
        let userPointer = try currentUser.toPointer()
        let locationPointer = try location.toPointer()
        let query = Bookmark.query("user" == userPointer, "location" == locationPointer)
        let matches = try await query.find()
        return !matches.isEmpty
    }

    // return true if bookmarked after toggle, false if removed
    @discardableResult
    static func toggleBookmark(for location: Location) async throws -> Bool {
        guard let currentUser = User.current else {
            throw BackendServiceError.notAuthenticated
        }
        let userPointer = try currentUser.toPointer()
        let locationPointer = try location.toPointer()

        let existing = try await Bookmark.query("user" == userPointer, "location" == locationPointer).find()
        if let first = existing.first {
            try await first.delete()
            return false
        } else {
            let bookmark = Bookmark(user: userPointer, location: locationPointer)
            _ = try await bookmark.save()
            return true
        }
    }

    // Reviews & Photo Upload

    static func fetchReviews(for location: Location) async throws -> [Review] {
        let locationPointer = try location.toPointer()
        let query = Review.query("location" == locationPointer)
            .include(["author"])
            .order([.descending("createdAt")])
        return try await query.find()
    }

    static func fetchUserReviews() async throws -> [Review] {
        guard let currentUser = User.current else {
            throw BackendServiceError.notAuthenticated
        }
        let authorPointer = try currentUser.toPointer()
        let query = Review.query("author" == authorPointer)
            .include(["location"])
            .order([.descending("createdAt")])
        return try await query.find()
    }

    @discardableResult
    static func submitReview(
        for location: Location,
        rating: Int,
        comment: String,
        imageData: Data? = nil
    ) async throws -> Review {
        guard let currentUser = User.current else {
            throw BackendServiceError.notAuthenticated
        }
        let authorPointer = try currentUser.toPointer()
        let locationPointer = try location.toPointer()

        var uploadedPhoto: ParseFile?
        if let imageData {
            let file = ParseFile(name: "review_\(UUID().uuidString).jpg", data: imageData)
            uploadedPhoto = try await file.save()
        }

        let review = Review(
            author: authorPointer,
            location: locationPointer,
            rating: rating,
            comment: comment,
            photo: uploadedPhoto
        )
        let savedReview = try await review.save()

        let allReviews = try await fetchReviews(for: location)
        let ratings = allReviews.compactMap(\.rating)
        if !ratings.isEmpty {
            let avg = Double(ratings.reduce(0, +)) / Double(ratings.count)
            var updatedLocation = location
            updatedLocation.averageRating = avg
            _ = try await updatedLocation.save()
        }

        return savedReview
    }

    // Profile & Session

    static func currentUserDisplayName() -> String {
        User.current?.fullName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
            ? User.current!.fullName!
            : (User.current?.email ?? User.current?.username ?? "Student")
    }

    static func currentUserEmail() -> String {
        User.current?.email ?? User.current?.username ?? ""
    }

    static func logout() async throws {
        try await User.logout()
    }
}
