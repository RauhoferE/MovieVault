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
        let release_date: String
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
    let release_date: String
    let revenue: Int
    let runtime: Int
    let spoken_languages: [SpokenLanguage]
    let status: String
    let tagline: String
    let title: String
    let video: Bool
    let vote_average: Double
    let vote_count: Int

    struct Genre: Decodable{
        let id: Int
        let name: String
    }
    struct ProductionCompany: Decodable{
        let id: Int
        let logo_path: String
        let name: String
        let origin_country: String
    }
    struct ProductionCountry: Decodable{
        let iso_3166_1: String
        let name: String
    }
    struct SpokenLanguage: Decodable{
        let iso_639_1: String
        let name: String
        let english_name: String
    }

}
