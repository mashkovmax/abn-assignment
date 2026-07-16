//
//  LocationsResponse.swift
//  PlacesApp
//
//  Created by Max Mashkov on 15/07/2026.
//


import Foundation

/// Top-level shape of `locations.json`: `{ "locations": [ ... ] }`.
struct LocationsResponse: Codable, Sendable {
    let locations: [Location]
}