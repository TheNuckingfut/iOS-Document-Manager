import Foundation
import Combine

/**
 * API Error Types
 *
 * Represents the various errors that can occur during network operations.
 * Each case provides specific information about what went wrong during
 * API interactions.
 */
enum APIError: Error {
    /// URL could not be constructed properly
    case invalidURL
    
    /// Response from server was not valid HTTP response
    case invalidResponse
    
    /// Network request failed with underlying error
    case requestFailed(Error)
    
    /// JSON decoding failed with underlying error
    case decodingFailed(Error)
    
    /// Server returned an error status code
    case serverError(Int)
    
    /// Unknown or unspecified error
    case unknown
}

/**
 * API Service
 *
 * Handles all network communication with the document server.
 * Implements RESTful API operations to create, read, update and delete documents.
 *
 * Uses Combine framework to provide asynchronous, publisher-based API.
 * All methods return publishers that emit either the requested data or an error.
 */
class APIService {
    /// Shared instance of the API Service (Singleton)
    static let shared = APIService()
    
    /// Base URL for the API endpoints
    private let baseURL = "https://67ff5bb258f18d7209f0debe.mockapi.io"
    
    /// JSON decoder configured for API responses
    private let jsonDecoder: JSONDecoder
    
    /// JSON encoder configured for API requests
    private let jsonEncoder: JSONEncoder
    
    /**
     * Private initializer to enforce singleton pattern
     *
     * Configures JSON encoder and decoder with proper date handling
     * and formatting options for API communication.
     */
    private init() {
        jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        
        jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .iso8601
        jsonEncoder.outputFormatting = .prettyPrinted
    }
    
    // MARK: - API Methods
    
    /**
     * Fetches all documents from the server
     *
     * Performs a GET request to retrieve a list of all documents.
     * The response is decoded into an array of DocumentDTO objects.
     *
     * - Returns: A publisher that emits either an array of DocumentDTO objects or an APIError
     */
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
    
    /**
     * Creates a new document on the server
     *
     * Performs a POST request to create a new document with the provided data.
     * The document is encoded as JSON in the request body.
     * On success, the server responds with the created document (including server-assigned fields).
     *
     * - Parameter document: The DocumentDTO containing the document data to create
     * - Returns: A publisher that emits either the created DocumentDTO or an APIError
     */
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
    
    /**
     * Updates an existing document on the server
     *
     * Performs a PUT request to update a document with the specified ID.
     * The document data is encoded as JSON in the request body.
     * On success, the server responds with the updated document.
     *
     * - Parameters:
     *   - id: The unique identifier of the document to update
     *   - document: The DocumentDTO containing the updated document data
     * - Returns: A publisher that emits either the updated DocumentDTO or an APIError
     */
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
    
    /**
     * Deletes a document from the server
     *
     * Performs a DELETE request to remove a document with the specified ID.
     * Unlike other API methods, this one returns Void on success since
     * deletion operations typically don't return content.
     *
     * - Parameter id: The unique identifier of the document to delete
     * - Returns: A publisher that emits either Void (on success) or an APIError
     */
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
