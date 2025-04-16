import Foundation

protocol OpenAIManagerDelegate: AnyObject {
    func openAIManager(_ manager: OpenAIManager, didGenerateSummaryKeywords keywords: [String])
    func openAIManager(_ manager: OpenAIManager, didFailWithError error: Error)
}

class OpenAIManager {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private(set) var lastProcessedText: String?
    
    weak var delegate: OpenAIManagerDelegate?
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func generateSummaryKeywords(from text: String) {
        print("🔑 Starting OpenAI API request for text: \(text)")
        lastProcessedText = text
        
        // Kelime sayısını hesapla
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        
        // Kelime sayısına göre farklı prompt'lar kullan
        let systemPrompt: String
        let userPrompt: String
        
        if wordCount < 10 {
            systemPrompt = "You are a helpful assistant that analyzes very short text segments. Focus on extracting the most meaningful words or phrases that represent the core message."
            userPrompt = "This is a very short text. Please analyze it and provide 2-3 meaningful keywords that best represent its content. Return only the keywords separated by commas: \(text)"
        } else if wordCount < 30 {
            systemPrompt = "You are a helpful assistant that extracts key points from text. Focus on identifying the main topics and themes."
            userPrompt = "Extract 3-4 key points from this text. Return only the keywords separated by commas: \(text)"
        } else {
            systemPrompt = "You are a helpful assistant that extracts key points from text. Focus on identifying the main topics, themes, and important concepts."
            userPrompt = "Extract 5-7 key points from this text. Return only the keywords separated by commas: \(text)"
        }
        
        // Prepare API request
        guard let apiURL = URL(string: baseURL) else {
            let error = NSError(domain: "OpenAIManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
            print("❌ Invalid API URL")
            delegate?.openAIManager(self, didFailWithError: error)
            return
        }
        
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 100
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            request.httpBody = jsonData
        } catch {
            print("❌ JSON serialization error: \(error)")
            delegate?.openAIManager(self, didFailWithError: error)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print(" Network error: \(error)")
                self.delegate?.openAIManager(self, didFailWithError: error)
                return
            }
            
            guard let data = data else {
                print(" No data received from API")
                let error = NSError(domain: "OpenAIManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                self.delegate?.openAIManager(self, didFailWithError: error)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    let keywords = content.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    
                    DispatchQueue.main.async {
                        self.delegate?.openAIManager(self, didGenerateSummaryKeywords: keywords)
                    }
                } else {
                    print("❌ Failed to parse OpenAI response")
                    let error = NSError(domain: "OpenAIManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])
                    self.delegate?.openAIManager(self, didFailWithError: error)
                }
            } catch {
                print("❌ JSON parsing error: \(error)")
                self.delegate?.openAIManager(self, didFailWithError: error)
            }
        }
        
        task.resume()
    }
} 
