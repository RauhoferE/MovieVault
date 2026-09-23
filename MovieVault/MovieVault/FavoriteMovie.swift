//
//  FavoriteMovie.swift
//  MovieVault
//
//  Created by emre on 23.09.26.
//

import SwiftData
import Foundation

@Model
final class FavoriteMovie {
    @Attribute(.unique) var id: Int
    var adult: Bool
    var backdrop_path: String
    var budget: Int
    var genres: [MovieDetails.Genre]
    var imdb_id: String
    var origin_country: [String]
    var original_language: String
    var original_title: String
    var overview: String
    var popularity: Double
    var poster_path: String
    var production_companies: [MovieDetails.ProductionCompany]
    var production_countries: [MovieDetails.ProductionCountry]
    var release_date: Date
    var revenue: Int
    var runtime: Int
    var spoken_languages: [MovieDetails.SpokenLanguage]
    var status: String
    var tagline: String
    var title: String
    var video: Bool
    var vote_average: Double
    var vote_count: Int

    init(from details: MovieDetails) {
        self.id = details.id
        self.adult = details.adult
        self.backdrop_path = details.backdrop_path
        self.budget = details.budget
        self.genres = details.genres
        self.imdb_id = details.imdb_id
        self.origin_country = details.origin_country
        self.original_language = details.original_language
        self.original_title = details.original_title
        self.overview = details.overview
        self.popularity = details.popularity
        self.poster_path = details.poster_path
        self.production_companies = details.production_companies
        self.production_countries = details.production_countries
        self.release_date = details.release_date
        self.revenue = details.revenue
        self.runtime = details.runtime
        self.spoken_languages = details.spoken_languages
        self.status = details.status
        self.tagline = details.tagline
        self.title = details.title
        self.video = details.video
        self.vote_average = details.vote_average
        self.vote_count = details.vote_count
    }
}
