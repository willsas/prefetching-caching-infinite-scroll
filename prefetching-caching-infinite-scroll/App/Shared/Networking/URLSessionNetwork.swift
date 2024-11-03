import Foundation

class URLSessionNetwork {
    private let urlSession: URLSession

    init(configuration: URLSessionConfiguration = .default) {
        urlSession = URLSession(configuration: configuration)
    }

    // Function to perform a GET request
    func get<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await urlSession.data(from: url)

        // Check for HTTP errors
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        // Decode the data into the expected type
        let decodedData = try JSONDecoder().decode(T.self, from: data)
        return decodedData
    }

    // Function to perform a POST request
    func post<T: Encodable, R: Decodable>(url: URL, body: T) async throws -> R {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Encode the body to JSON
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)

        // Check for HTTP errors
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode)
        else {
            throw URLError(.badServerResponse)
        }

        // Decode the response data
        let decodedData = try JSONDecoder().decode(R.self, from: data)
        return decodedData
    }
}
