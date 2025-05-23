//
//  RecordingModel.swift
//  AudioDoc-NeonApps
//
//  Created by Kerem on 2.04.2025.
//

import Foundation
import Firebase

struct Recording: Codable {
    let id: String
    let title: String
    let summaryKeywords: [String]
    let transcription: String
    let createdAt: Date
    let duration: Int
    let audioURL: String
    let tags: [String]
    let imageURL: String?
    

    init(title: String, summaryKeywords: [String], transcription: String, 
         createdAt: Date, duration: Int, audioURL: String, tags: [String] = [], imageURL: String? = nil) {
        self.id = UUID().uuidString
        self.title = title
        self.summaryKeywords = summaryKeywords
        self.transcription = transcription
        self.createdAt = createdAt
        self.duration = duration
        self.audioURL = audioURL
        self.tags = tags
        self.imageURL = imageURL
    }
    
    // Firestore'dan dönüştürme işlemi için initializer
    init?(document: DocumentSnapshot) {
        guard 
            let data = document.data(),
            let title = data["title"] as? String,
            let summaryKeywords = data["summaryKeywords"] as? [String],
            let transcription = data["transcription"] as? String,
            let timestamp = data["createdAt"] as? Timestamp,
            let duration = data["duration"] as? Int,
            let audioURL = data["audioURL"] as? String,
            let tags = data["tags"] as? [String]
        else {
            return nil
        }
        
        self.id = document.documentID
        self.title = title
        self.summaryKeywords = summaryKeywords
        self.transcription = transcription
        self.createdAt = timestamp.dateValue()
        self.duration = duration
        self.audioURL = audioURL
        self.tags = tags
        self.imageURL = data["imageURL"] as? String
    }
    
    // Firestore'a kayıt için dictionary dönüşümü
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "title": title,
            "summaryKeywords": summaryKeywords,
            "transcription": transcription,
            "createdAt": Timestamp(date: createdAt),
            "duration": duration,
            "audioURL": audioURL,
            "tags": tags
        ]
        
        if let imageURL = imageURL {
            dict["imageURL"] = imageURL
        }
        
        return dict
    }
    
   
}
