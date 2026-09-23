//
//  Networking.swift
//  MovieVault
//
//  Created by emre on 23.09.26.
//

import Foundation

public enum HTTPMethod: String{
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
    case patch = "PATCH"
}

public enum APIError: Error, LocalizedError{
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case serilizationError
    case networkError
    case unknownError

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid Response"
        case .serilizationError:
            return "Error when serializing data"
        case .networkError:
            return "Please connect to the internet"
        case .unknownError:
            return "Unknown Error"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        }
    }
}

class NetworkManager {
    private let session: URLSession
    private let APIKEY: String

    init(session: URLSession = .shared){
        self.session = session
        self.APIKEY = Secrets.apiKey
    }

    func getMovies(page: Int) async throws -> MoviesResponse{
        guard let url = URL(string: "https://api.themoviedb.org/3/trending/movie/week?page=\(page)") else {
            
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIKEY)", forHTTPHeaderField: "Authorization")
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw APIError.networkError
        } catch {
            throw APIError.unknownError
        }
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode){
            throw APIError.invalidResponse
        }
        
        do{
            let docRes = try JSONDecoder().decode(MoviesResponse.self, from: data)
            return docRes
        }catch {
            throw APIError.serilizationError
        }
    }
    
    func getMovieDetails(id: Int) async throws -> MovieDetails{
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/\(id)") else {
            
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(APIKEY)", forHTTPHeaderField: "Authorization")
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet {
            throw APIError.networkError
        } catch {
            throw APIError.unknownError
        }
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode){
            throw APIError.invalidResponse
        }
        
        do{
            let docRes = try JSONDecoder().decode(MovieDetails.self, from: data)
            return docRes
        }catch {
            throw APIError.serilizationError
        }
    }
    


}
