//
//  Models.swift
//  CampusSpot
//
//  Created by amanda torres on 11/22/26.
//

import Foundation
import ParseSwift

// User (_User)

struct User: ParseUser {
    // Required ParseObject fields
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Required ParseUser fields
    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?

    var fullName: String?
}

// Location

struct Location: ParseObject {
    // Required ParseObject fields
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    // Custom columns matching Back4App Location class
    var name: String?
    var campus: String? // Stores "MMC", "BBC", or "EC"
    var description: String?
    var environment: String?
    var noiseLevel: String?
    var hasOutlets: Bool?
    var image: ParseFile?
    var averageRating: Double?

    var campusEnum: Campus? {
        guard let campus else { return nil }
        return Campus.allCases.first { $0.shortName.caseInsensitiveCompare(campus) == .orderedSame }
    }
}

extension Location {
    func toStudySpot() -> StudySpot {
        StudySpot(
            id: objectId ?? UUID().uuidString,
            name: name ?? "Unnamed Study Spot",
            campus: campusEnum ?? .mmc,
            description: description ?? "",
            environment: environment ?? "General",
            noiseLevel: noiseLevel,
            hasOutlets: hasOutlets,
            averageRating: averageRating
        )
    }
}


// Review
struct Review: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var spotId: String?
    var userId: String?
    var rating: Int?
    var comment: String?
}

// Bookmark
struct Bookmark: ParseObject {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var spotId: String?
    var userId: String?
}

