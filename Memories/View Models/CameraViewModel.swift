//
//  CameraViewModel.swift
//  Memories
//
//  Created by Fadey Notchenko on 06.11.2022.
//

import Foundation
import SwiftUI
import AVKit

class CameraViewModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate, AVCaptureFileOutputRecordingDelegate {
    
    @Published var isTaken: Bool = false
    @Published var alert: Bool = false
    @Published var session = AVCaptureSession()
    @Published var picOutput = AVCapturePhotoOutput()
    
    @Published var preview: AVCaptureVideoPreviewLayer!
    @Published var position: AVCaptureDevice.Position = .back
    
    @Published var isSaved: Bool = false
    @Published var mediaData = Data(count: 0)
    
    @Published var video: Bool = false
    @Published var videoOutput = AVCaptureMovieFileOutput()
    
    @Published var isRecording: Bool = false
    @Published var previewURL: URL?
    
    @Published var recordedDuration: Double = 0
    
    @Published var recordPermission: AVAudioSession.RecordPermission = .undetermined
    
    @Published var permission = false
    
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.permission = true
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.permission = true
                    
                    self.setUp()
                }
            }
        case .denied:
            self.permission = false
            alert.toggle()
            return
        default:
            return
        }
        
    }
    
    func setUp() {
        do {
            self.session.beginConfiguration()
            
            // remove all inputs and outputs from the session
            for input in session.inputs { session.removeInput(input) }
            for output in session.outputs { session.removeOutput(output) }
            
            let device = bestDevice(in: position)
            let input = try AVCaptureDeviceInput(device: device)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.picOutput) {
                self.session.addOutput(self.picOutput)
            }
            
            self.session.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
        
    }
    
    let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:
                                                                [.builtInTrueDepthCamera, .builtInDualCamera, .builtInWideAngleCamera],
                                                            mediaType: .video, position: .unspecified)
    
    func bestDevice(in position: AVCaptureDevice.Position) -> AVCaptureDevice {
        let devices = self.discoverySession.devices
        guard !devices.isEmpty else { fatalError("Missing capture devices.")}
        
        return devices.first(where: { device in device.position == position })!
    }
    
    // take and retake functions...
    
    func takePic() {
        DispatchQueue.global(qos: .userInteractive).async {
            self.picOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                }
            }
        }
    }
    
    func retakePic() {
        setUp()
        
        DispatchQueue.global(qos: .userInteractive).async {
            self.session.startRunning()
            
            DispatchQueue.main.async {
                withAnimation {
                    self.isTaken.toggle()
                    self.isTaken = false
                    self.previewURL = nil
                }
            }
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if error != nil {
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        self.mediaData = imageData
        self.isTaken = true
        savePhoto()
    }
    
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        if error != nil {
            print(error?.localizedDescription)
            return
        }
        
        previewURL = outputFileURL
        self.isTaken = true
        
        do {
            try self.mediaData = Data(contentsOf: outputFileURL)
        } catch {
            print("error occurred")
        }
    }
    
    func savePhoto() {
        
        if let uiImage = UIImage(data: mediaData) {
            if let data = uiImage.jpegData(compressionQuality: 0.8) {
                let tempFile = NSTemporaryDirectory() + "photo.jpg"
                try? data.write(to: URL(fileURLWithPath: tempFile))
                self.previewURL = URL(fileURLWithPath: tempFile)
            }
        }
    }
}
