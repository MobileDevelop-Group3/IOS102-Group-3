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


    // Bookmarks

    static func fetchUserBookmarks() async throws -> [Bookmark] {
        guard let userId = User.current?.objectId else {
            throw BackendServiceError.notAuthenticated
        }

        let query = Bookmark.query("userId" == userId)
            .order([.descending("createdAt")])

        return try await query.find()
    }

    static func isBookmarked(spotId: String) async throws -> Bool {
        guard let userId = User.current?.objectId else {
            throw BackendServiceError.notAuthenticated
        }

        let query = Bookmark.query(
            "userId" == userId,
            "spotId" == spotId
        )

        let matches = try await query.find()
        return !matches.isEmpty
    }

    @discardableResult
    static func toggleBookmark(for spotId: String) async throws -> Bool {
        guard let userId = User.current?.objectId else {
            throw BackendServiceError.notAuthenticated
        }

        let existing = try await Bookmark.query(
            "userId" == userId,
            "spotId" == spotId
        ).find()

        if let first = existing.first {
            try await first.delete()
            return false
        } else {
            let bookmark = Bookmark(
                spotId: spotId,
                userId: userId
            )

            _ = try await bookmark.save()
            return true
        }
    }



    // Reviews

    static func fetchReviews(for spotId: String) async throws -> [Review] {
        let query = Review.query("spotId" == spotId)
            .order([.descending("createdAt")])

        return try await query.find()
    }

    static func fetchUserReviews() async throws -> [Review] {
        guard let userId = User.current?.objectId else {
            throw BackendServiceError.notAuthenticated
        }

        let query = Review.query("userId" == userId)
            .order([.descending("createdAt")])

        return try await query.find()
    }

    @discardableResult
    static func submitReview(
        for spotId: String,
        rating: Int,
        comment: String
    ) async throws -> Review {
        guard let userId = User.current?.objectId else {
            throw BackendServiceError.notAuthenticated
        }

        let review = Review(
            spotId: spotId,
            userId: userId,
            rating: rating,
            comment: comment
        )

        return try await review.save()
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
