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
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid Response"
        case .serilizationError:
            return "Error when serializing data"
        case .httpError(let code):
            return "HTTP Error: \(code)"
        }
    }
}

class NetworkManager {
    private let session: URLSession
    private let APIKEY: String = ""
    
    init(session: URLSession = .shared){
        self.session = session
    }
    
    func getCountries(idToken: String, completion: @escaping ([Country]?, NetworkError?) -> Void){
        guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/mad-fe/databases/(default)/documents/countries?pageSize=1000&orderBy=name") else {
            
            completion(nil, .invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")

        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            
            if let error = error as NSError?{
                DispatchQueue.main.async {
                    completion(nil, .networkOffline)
                }
                
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, .noData)
                }
                
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode){
                if let apiError = try? JSONDecoder().decode(CountriesAPIError.self, from: data){
                    let mappedError = self.mapCountriesAPIError(apiError.status, statusCode: apiError.code)
                    DispatchQueue.main.async {
                        completion(nil, mappedError)
                    }
                    
                    
                }else{
                    DispatchQueue.main.async {
                        completion(nil, .serverError(statusCode: httpResponse.statusCode))
                    }

                }

                return
            }
            

            
            do{
                
                let docRes = try JSONDecoder().decode(DocumentsContainer.self, from: data)
                
            DispatchQueue.main.async {
                completion(docRes.documents, nil)
                }
            }catch {
                DispatchQueue.main.async {
                    completion(nil, .unexpectedDataFormat)
                }
                
            }
            
            
        }
        task.resume()
    }
    
    func login(email: String, password: String, completion: @escaping (User?, NetworkError?) -> Void){
        guard let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=\(APIKEY)") else {
            
            completion(nil, .invalidURL)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "email":email,
            "password":password,
            "returnSecureToken":true
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }
            catch {
                completion(nil, .serializationFailed)
                
                return
            }
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            
            if let error = error as NSError?{
                DispatchQueue.main.async {
                    completion(nil, .networkOffline)
                }
                
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, .noData)
                }
                
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode){
                if let apiError = try? JSONDecoder().decode(ResponseError.self, from: data){
                    let mappedError = self.mapAPIError(apiError.error.message, statusCode: apiError.error.code)
                    DispatchQueue.main.async {
                        completion(nil, mappedError)
                    }
                    
                    
                }else{
                    DispatchQueue.main.async {
                        completion(nil, .serverError(statusCode: httpResponse.statusCode))
                    }

                }

                return
            }
            

            
            do{
                
                let loginResponse = try JSONDecoder().decode(User.self, from: data)
                
            DispatchQueue.main.async {
                    completion(loginResponse, nil)
                }
            }catch {
                DispatchQueue.main.async {
                    completion(nil, .unexpectedDataFormat)
                }
                
            }
            
            
        }
        task.resume()
        
    }
    
    private func mapAPIError(_ message: String, statusCode: Int) -> NetworkError {
        switch message {
        case "INVALID_EMAIL":
            return .invalidEmailFormat
        case "INVALID_LOGIN_CREDENTIALS":
            return .incorrectPassword
        default:
            return .serverError(statusCode: statusCode)
        }
    }
    
    private func mapCountriesAPIError(_ status: String, statusCode: Int) -> NetworkError {
        switch status {
        case "PERMISSION_DENIED":
            return .denied
        case "UNAUTHENTICATED":
            return .unauth
        default:
            return .serverError(statusCode: statusCode)
        }
    }
}
