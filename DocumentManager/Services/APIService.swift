import Foundation

/**
 * API Service
 *
 * Handles network requests to the documents API.
 * Responsible for fetching, creating, updating, and deleting documents on the server.
 */
class APIService {
    static let shared = APIService()
    
    /// Base URL for the documents API
    private let baseURL = URL(string: "https://67ff5bb258f18d7209f0debe.mockapi.io/documents")!
    
    /// URLSession for making network requests
    private let session: URLSession
    
    /// JSON decoder for parsing API responses
    private let decoder = JSONDecoder()
    
    /// JSON encoder for creating request bodies
    private let encoder = JSONEncoder()
    
    /// Errors that can occur when using the API service
    enum APIError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingFailed(Error)
        case serverError(Int)
        case networkUnavailable
        case unknown
    }
    
    /**
     * Initialize the API service
     *
     * Configures the URLSession for network requests.
     */
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        session = URLSession(configuration: config)
        
        // Configure date decoding strategy
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }
    
    /**
     * Fetch all documents from the server
     *
     * Retrieves the list of documents from the API.
     *
     * - Parameter completion: Closure called when the fetch completes
     */
    func fetchDocuments(completion: @escaping (Result<[[String: Any]], APIError>) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.failure(.networkUnavailable))
            return
        }
        
        let task = session.dataTask(with: baseURL) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(.serverError(statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                    completion(.success(json))
                } else {
                    completion(.failure(.invalidResponse))
                }
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }
        
        task.resume()
    }
    
    /**
     * Upload a new document to the server
     *
     * Creates a new document on the server.
     *
     * - Parameters:
     *   - document: The document data to upload
     *   - completion: Closure called when the upload completes
     */
    func uploadDocument(_ document: [String: Any], completion: @escaping (Result<[String: Any], APIError>) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.failure(.networkUnavailable))
            return
        }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: document)
        } catch {
            completion(.failure(.requestFailed(error)))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(.serverError(statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(.invalidResponse))
                }
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }
        
        task.resume()
    }
    
    /**
     * Update an existing document on the server
     *
     * Updates a document with new data.
     *
     * - Parameters:
     *   - documentId: The ID of the document to update
     *   - document: The updated document data
     *   - completion: Closure called when the update completes
     */
    func updateDocument(documentId: String, document: [String: Any], completion: @escaping (Result<[String: Any], APIError>) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.failure(.networkUnavailable))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/\(documentId)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: document)
        } catch {
            completion(.failure(.requestFailed(error)))
            return
        }
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(.serverError(statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(.invalidResponse))
                }
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }
        
        task.resume()
    }
    
    /**
     * Delete a document from the server
     *
     * Removes a document from the API.
     *
     * - Parameters:
     *   - documentId: The ID of the document to delete
     *   - completion: Closure called when the deletion completes
     */
    func deleteDocument(documentId: String, completion: @escaping (Result<Bool, APIError>) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.failure(.networkUnavailable))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/\(documentId)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(.serverError(statusCode)))
                return
            }
            
            completion(.success(true))
        }
        
        task.resume()
    }
    
    /**
     * Fetch a single document from the server by ID
     *
     * Retrieves detailed information about a specific document.
     *
     * - Parameters:
     *   - documentId: The ID of the document to fetch
     *   - completion: Closure called when the fetch completes
     */
    func fetchDocument(documentId: String, completion: @escaping (Result<[String: Any], APIError>) -> Void) {
        guard NetworkMonitor.shared.isConnected else {
            completion(.failure(.networkUnavailable))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/\(documentId)") else {
            completion(.failure(.invalidURL))
            return
        }
        
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                completion(.failure(.serverError(statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.invalidResponse))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(.success(json))
                } else {
                    completion(.failure(.invalidResponse))
                }
            } catch {
                completion(.failure(.decodingFailed(error)))
            }
        }
        
        task.resume()
    }
}