//
//  Movie.swift
//  MovieVault
//
//  Created by emre on 23.09.26.
//

import Foundation
//https://api.themoviedb.org/3/trending/movie/week
nonisolated struct MoviesResponse: Decodable{
    let page: Int
    let total_results: Int
    let total_pages: Int
    let results: [Movie]
    struct Movie: Decodable{
        let adult: Bool
        let backdrop_path: String
        let id: Int
        let title: String
        let original_language: String
        let original_title: String
        let overview: String
        let poster_path: String
        let media_type: String
        let genre_ids: [Int]
        let popularity: Double
        @DateFormatted var release_date: Date
        let video: Bool
        let vote_average: Double
        let vote_count: Int
    }
}

nonisolated struct MovieDetails: Decodable{
    let adult: Bool
    let backdrop_path: String
    let budget: Int
    let genres: [Genre]
    let id: Int
    let imdb_id: String
    let origin_country: [String]
    let original_language: String
    let original_title: String
    let overview: String
    let popularity: Double
    let poster_path: String
    let production_companies: [ProductionCompany]
    let production_countries: [ProductionCountry]
    @DateFormatted var release_date: Date
    let revenue: Int
    let runtime: Int
    let spoken_languages: [SpokenLanguage]
    let status: String
    let tagline: String
    let title: String
    let video: Bool
    let vote_average: Double
    let vote_count: Int

    struct Genre: Codable{
        let id: Int
        let name: String
    }
    struct ProductionCompany: Codable{
        let id: Int
        let name: String
        let origin_country: String
    }
    struct ProductionCountry: Codable{
        let iso_3166_1: String
        let name: String
    }
    struct SpokenLanguage: Codable{
        let iso_639_1: String
        let name: String
        let english_name: String
    }

}

@propertyWrapper
struct DateFormatted: Decodable {
    let wrappedValue: Date

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Date string \(dateString) does not match format yyyy-MM-dd"
            )
        }
        self.wrappedValue = date
    }
}

struct MovieVideosResponse: Decodable {
    let id: Int
    let results: [Video]

    struct Video: Decodable {
        let key: String
        let site: String
        let type: String
        let official: Bool
    }
}
