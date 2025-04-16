import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(Error)
    case decodingFailed(Error)
    case serverError(Int)
    case unknown
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://67ff5bb258f18d7209f0debe.mockapi.io"
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    
    private init() {
        jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.outputFormatting = .prettyPrinted
    }
    
    // MARK: - API Methods
    
    /// Fetch all documents from the server
    func fetchDocuments() -> AnyPublisher<[DocumentDTO], APIError> {
        let endpoint = "/documents"
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if (200..<300).contains(httpResponse.statusCode) {
                    return data
                } else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
            .decode(type: [DocumentDTO].self, decoder: jsonDecoder)
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.decodingFailed(error)
                } else {
                    return APIError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Create a new document on the server
    func createDocument(document: DocumentDTO) -> AnyPublisher<DocumentDTO, APIError> {
        let endpoint = "/documents"
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try jsonEncoder.encode(document)
        } catch {
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if (200..<300).contains(httpResponse.statusCode) {
                    return data
                } else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
            .decode(type: DocumentDTO.self, decoder: jsonDecoder)
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.decodingFailed(error)
                } else {
                    return APIError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Update an existing document on the server
    func updateDocument(id: String, document: DocumentDTO) -> AnyPublisher<DocumentDTO, APIError> {
        let endpoint = "/documents/\(id)"
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try jsonEncoder.encode(document)
        } catch {
            return Fail(error: APIError.requestFailed(error)).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if (200..<300).contains(httpResponse.statusCode) {
                    return data
                } else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
            .decode(type: DocumentDTO.self, decoder: jsonDecoder)
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.decodingFailed(error)
                } else {
                    return APIError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    /// Delete a document from the server
    func deleteDocument(id: String) -> AnyPublisher<Void, APIError> {
        let endpoint = "/documents/\(id)"
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { _, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if (200..<300).contains(httpResponse.statusCode) {
                    return
                } else {
                    throw APIError.serverError(httpResponse.statusCode)
                }
            }
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else {
                    return APIError.requestFailed(error)
                }
            }
            .eraseToAnyPublisher()
    }
}
