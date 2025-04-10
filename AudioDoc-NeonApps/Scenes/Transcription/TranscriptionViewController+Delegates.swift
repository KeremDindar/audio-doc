import UIKit
import AVFoundation

// MARK: - AVAudioPlayerDelegate
extension TranscriptionViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        player.currentTime = 0
    }
}

// MARK: - UIImagePickerControllerDelegate
extension TranscriptionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let editedImage = info[.editedImage] as? UIImage {
            self.selectedImage = editedImage
            self.setSelectedImage(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            self.selectedImage = originalImage
            self.setSelectedImage(originalImage)
        }
        
        dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension TranscriptionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == tagInputTextField {
            addTagButtonTapped()
        }
        return true
    }
}

// MARK: - AudioPlayerManagerDelegate
extension TranscriptionViewController: AudioPlayerManagerDelegate {
    func audioPlayerManager(_ manager: AudioPlayerManager, didUpdateCurrentTime time: TimeInterval) {
        currentTimeLabel.text = manager.formatTime(time)
        progressSlider.value = Float(time / manager.duration)
    }
    
    func audioPlayerManager(_ manager: AudioPlayerManager, didUpdatePlaybackState isPlaying: Bool) {
        let imageName = isPlaying ? "pause.circle.fill" : "play.circle.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    func audioPlayerManagerDidFinishPlaying(_ manager: AudioPlayerManager) {
        let imageName = "play.circle.fill"
        playButton.setImage(UIImage(systemName: imageName), for: .normal)
        currentTimeLabel.text = "00:00"
        progressSlider.value = 0
    }
} 
