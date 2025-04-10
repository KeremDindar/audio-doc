import Foundation

protocol OpenAIManagerDelegate: AnyObject {
    func openAIManager(_ manager: OpenAIManager, didGenerateSummaryKeywords keywords: [String])
    func openAIManager(_ manager: OpenAIManager, didFailWithError error: Error)
}

class OpenAIManager {
    // MARK: - Properties
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private(set) var lastProcessedText: String?
    
    weak var delegate: OpenAIManagerDelegate?
    
    // MARK: - Initialization
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    func generateSummaryKeywords(from text: String) {
        lastProcessedText = text
        
        // Prepare API request
        guard let apiURL = URL(string: baseURL) else {
            let error = NSError(domain: "OpenAIManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            delegate?.openAIManager(self, didFailWithError: error)
            return
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that extracts meaningful and diverse key summary keywords from text. Be specific and extract important themes and concepts."],
                ["role": "user", "content": "Extract 5-7 unique and descriptive key summary keywords from this text. Try to identify the main topics and themes. Return only the keywords separated by commas, with no additional text: \(text)"]
            ],
            "temperature": 0.7,
            "max_tokens": 100
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        } catch {
            delegate?.openAIManager(self, didFailWithError: error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.delegate?.openAIManager(self, didFailWithError: error)
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "OpenAIManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                self.delegate?.openAIManager(self, didFailWithError: error)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Extract the keywords
                    let keywords = content.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    
                    DispatchQueue.main.async {
                        self.delegate?.openAIManager(self, didGenerateSummaryKeywords: keywords)
                    }
                } else {
                    let error = NSError(domain: "OpenAIManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])
                    self.delegate?.openAIManager(self, didFailWithError: error)
                }
            } catch {
                self.delegate?.openAIManager(self, didFailWithError: error)
            }
        }
        
        task.resume()
    }
} 
