import Foundation

final class URLSessionNetwork {
    
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    enum NetworkError: Error {
        case invalidResponse
        case httpError(statusCode: Int)
        case decodingError(Error)
        case encodingError(Error)
    }
    
    init(
        configuration: URLSessionConfiguration = .ephemeral,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.urlSession = URLSession(configuration: configuration)
        self.decoder = decoder
        self.encoder = encoder
    }

    func get<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await urlSession.data(from: url)
        try handleResponse(response)
        
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    func post<T: Encodable, R: Decodable>(url: URL, body: T) async throws -> R {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw NetworkError.encodingError(error)
        }

        let (data, response) = try await urlSession.data(for: request)
        try handleResponse(response)
        
        do {
            return try decoder.decode(R.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }

    private func handleResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
        }
    }
}
