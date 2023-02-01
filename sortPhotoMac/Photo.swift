//
//  Photo.swift
//  sortPhotoMac
//
//  Created by Stefan Haßferter on 29.08.20.
//  Copyright © 2020 Stefan Haßferter. All rights reserved.
//

import Foundation
import SwiftyImageIO
import SwiftUI

class Photo {
    let fileUrl: URL
    var dateTime: Date?
    var urlAfterSorting: URL? = nil
    var selected: Bool = true
    var processed: FinishedType = .notProcessed
    
    internal init(fileUrl: URL) {
        self.fileUrl = fileUrl
        dateTime = DateFormatter.parseEXIFDate(from: Photo.loadDateString(for: fileUrl))
        ?? Photo.getLastModifiedDate(for: fileUrl)
    }
    
    func generateNewPath(config: SortConfiguration) {
        guard let date = dateTime else {
            return
        }
        var rootUrl = URL(fileURLWithPath: config.rootPath)
        
        if config.subDictionaryYear {
            rootUrl.appendPathComponent(DateFormatter.yearString(from: date))
        }
        
        if config.subDictionaryMonth {
            rootUrl.appendPathComponent(DateFormatter.monthString(from: date))
        }
        
        if config.subDictionaryDay {
            rootUrl.appendPathComponent(DateFormatter.dayString(from: date))
        }
        
        if config.renameFile {
            rootUrl.appendPathComponent(DateFormatter.datePath(from: date))
            rootUrl.appendPathExtension(fileUrl.pathExtension)
        } else {
            rootUrl.appendPathComponent(fileUrl.lastPathComponent)
        }
        
        urlAfterSorting = rootUrl
    }
    
    func moveToNewLocation() throws {
        guard let destinationUrl = urlAfterSorting else { return }
        let dicitonariyUrl = destinationUrl.deletingLastPathComponent()
        createDictionaryIfNeeded(for: dicitonariyUrl)
        do{
            try FileManager.default.moveItem(at: fileUrl,
                                             to: adaptPathForVersioningIfneeded(for: destinationUrl))
            processed = .moved
        } catch {
            processed = .failed
            print(error.localizedDescription)
        }
    }
    
    func copyToNewLocation() throws {
        guard let destinationUrl = urlAfterSorting else { return }
        let dicitonariyUrl = destinationUrl.deletingLastPathComponent()
        createDictionaryIfNeeded(for: dicitonariyUrl)
        
        do{
            try FileManager.default.copyItem(at: fileUrl,
                                             to: adaptPathForVersioningIfneeded(for: destinationUrl))
            processed = .moved
        } catch {
            processed = .failed
            print(error.localizedDescription)
        }
    }
    
    
    func createDictionaryIfNeeded(for url:URL) {
        if !FileManager.default.fileExists(atPath: url.path){
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    func adaptPathForVersioningIfneeded(for url: URL) -> URL {
        if FileManager.default.fileExists(atPath: url.path) {
            var counter = 1
            var newUrl = url
            
            while FileManager.default.fileExists(atPath: newUrl.path) {
                newUrl = addVersionCounter(to: url, counter: counter)
                counter += 1
            }
            return newUrl
        }
        return url
    }
    
    func reverseWhatsappTimestamp(){
        self.dateTime = createDataFromPath()
        self.dateTime = dateTime?.addingTimeInterval((12 * 60 * 60))
        //        writeDateToExifData(date: dateTime!)
    }
    
    func writeDateToExifData(date: Date?) {
        guard let date = date else {return}
        //        let source = ImageSource(url: fileUrl, options: nil)
        //        guard var properties = source?.propertiesForImage() else {
        //            return
        //        }
        ////        let properties2 = PhotoPropterties(RawCFValues(dictionaryLiteral: (kCGImagePropertyExifDateTimeOriginal, dateTime as AnyObject)))
        ////        properties.add(properties2)
        //
        //
        ////        return  properties.get(PhotoPropterties.self)?.dateTime ??
        ////            properties.get(TIFFImageProperties.self)?.dateTime ??
        //
        ////        sav
        ///eMetadata(<#T##data: NSDictionary##NSDictionary#>, toFile: fileUrl)
        addExifDate(date: date, toImage: nil)
        
        
        let attributes = [FileAttributeKey.creationDate: date, FileAttributeKey.modificationDate:date]
        
        do {
            if #available(macOS 13.0, *) {
                try FileManager.default.setAttributes(attributes, ofItemAtPath: fileUrl.path)
            } else {
                // Fallback on earlier versions
            }
        }
        catch
        {
            print(error)
        }
        // Set up destination
      
        
        
    }
    
    
    
    
    func addExifDate(date: Date?, toImage image: CIImage?) -> Dictionary<String, Any> {
        
        guard
            let sourceRef = CGImageSourceCreateWithURL(fileUrl as CFURL, nil),
            var metaData = CGImageSourceCopyPropertiesAtIndex(sourceRef, 0, nil) as? [String:Any],
            let date = date else {return[:]}
        
//        print("unmodified properties", metaData, separator:"\n")
        
        
        /// Check if image already have its meta data
        //        if let ciImage = image {
        //            metaData = ciImage.properties
        //        }
        
        /// Initializing the gpsData dict
        var exifImageData: Dictionary<String, Any> = [:]
        var tiffImageData: Dictionary<String, Any> = [:]
        
        /// Check if there is any gps information
        //        if let gps = metaData[kCGImagePropertyGPSDictionary as String] as? Dictionary<String, Any> {
        //            gpsData = gps
        //        }
        
        /// Adding all the required information to gpsData dictionary
        // #1. Data & Time
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        let localDate = DateFormatter.exifFormater.string(from: date)
        tiffImageData[kCGImagePropertyTIFFDateTime as String] = localDate
        exifImageData[kCGImagePropertyExifDateTimeOriginal as String] = localDate
        exifImageData[kCGImagePropertyExifDateTimeDigitized as String] = localDate
        
        //        // #2. Latitude, Longitude
        //        var latitude  = location.coordinate.latitude
        //        var longitude = location.coordinate.longitude
        //        var latRef = ""
        //        var lngRef = ""
        //        if latitude < 0.0 {
        //            latitude *= -1.0
        //            latRef = "S"
        //        } else  {
        //            latRef = "N"
        //        }
        //
        //        if longitude < 0.0 {
        //            longitude *= -1.0
        //            lngRef = "W"
        //        }
        //        else {
        //            lngRef = "E"
        //        }
        //
        //        gpsData[kCGImagePropertyGPSLatitudeRef as String] = latRef
        //        gpsData[kCGImagePropertyGPSLongitudeRef as String] = lngRef
        //        gpsData[kCGImagePropertyGPSLatitude as String] = latitude
        //        gpsData[kCGImagePropertyGPSLongitude as String] = longitude
        //
        //        // #3. Accuracy
        //        gpsData[kCGImagePropertyGPSDOP as String] = location.horizontalAccuracy
        //
        //        // #4. Altitude
        //        gpsData[kCGImagePropertyGPSAltitude as String] = location.altitude
        //
        //        /// You can add what more you want to add into gpsData and after that
        //        /// Add this gpsData information into metaData dictionary
        metaData[kCGImagePropertyTIFFDictionary as String] = tiffImageData
        metaData[kCGImagePropertyExifDictionary as String] = exifImageData
//        print("", "modified properties", metaData, separator:"\n")
        
        guard let destinationRef = CGImageDestinationCreateWithURL(fileUrl as CFURL, kUTTypeJPEG, 1, nil) else { return [:] }

        // Add image from source to destination with new properties
        CGImageDestinationAddImageFromSource(destinationRef, sourceRef, 0, metaData as CFDictionary)

        // Save destination
        guard CGImageDestinationFinalize(destinationRef) else { return [:]}

        guard
          let sourceRef2 = CGImageSourceCreateWithURL(fileUrl as CFURL, nil),
          let metadata2 = CGImageSourceCopyPropertiesAtIndex(sourceRef2, 0, nil) else { return [:] }

//        print("", "saved properties", metadata2, separator:"\n")
        return [:]
    }
    
    //    func saveImage(_ image:CIImage, withMetadata metaData: Dictionary<String, Any>) {
    //        /// Creating jpgData from UIImage (1 = original quality)
    //        guard let jpgData = UIImageJPEGRepresentation(image, 1) else { return }
    //
    //        /// Adding metaData to jpgData
    //        guard let source = CGImageSourceCreateWithData(jpgData as CFData, nil), let uniformTypeIdentifier = CGImageSourceGetType(source) else {
    //            return
    //        }
    //
    //        let finalData = NSMutableData(data: jpgData)
    //        guard let destination = CGImageDestinationCreateWithData(finalData, uniformTypeIdentifier, 1, nil) else { return }
    //        CGImageDestinationAddImageFromSource(destination, source, 0, metaData as CFDictionary)
    //        guard CGImageDestinationFinalize(destination) else { return }
    //
    //        /// Your destination file path
    //        let filePath = "\(documentsDicrectoryPath)/finalImage.jpg"
    //
    //        /// Now write this image to directory
    //        if FileManager.default.fileExists(atPath: filePath) {
    //            try? FileManager.default.removeItem(atPath: filePath)
    //        }
    //
    //        let success = FileManager.default.createFile(atPath: filePath, contents: finalData as Data, attributes: [FileAttributeKey.protectionKey : FileProtectionType.complete])
    //        if success {
    //            /// Finally Save image to Gallery
    //            /// Important you need PhotoGallery permission before performing below operation.
    //            try? PHPhotoLibrary.shared().performChangesAndWait {
    //                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: URL(fileURLWithPath: filePath))
    //            }
    //        }
    //    }
    
    
    func saveMetadata(_ data:NSDictionary, toFile url:URL) {
        // Add metadata to imageData
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let uniformTypeIdentifier = CGImageSourceGetType(source) else { return }
        
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, uniformTypeIdentifier, 1, nil) else { return }
        CGImageDestinationAddImageFromSource(destination, source, 0, data)
        guard CGImageDestinationFinalize(destination) else { return }
    }
    
    func createDataFromPath() -> Date? {
        guard let index = fileUrl.lastPathComponent.lastIndex(of: "W")
        else {
            print("error processing file: \(fileUrl)")
            return nil }
        let dateSting = fileUrl.lastPathComponent[..<index]
        return DateFormatter.whatsappFileFormater.date(from: String(dateSting))
    }
    
    func addVersionCounter(to url: URL, counter: Int) -> URL {
        var newUrl = url
        let fileExtension = url.pathExtension
        newUrl.deletePathExtension()
        var lastComponent = newUrl.lastPathComponent
        newUrl.deleteLastPathComponent()
        lastComponent.append("-\(counter)")
        newUrl.appendPathComponent(lastComponent)
        newUrl.appendPathExtension(fileExtension)
        return newUrl
    }
    
    static func loadDateString(for url: URL) -> String? {
        let source = ImageSource(url: url, options: nil)
        guard let properties = source?.propertiesForImage() else {
            return nil;
        }
        
//        print(source?.propertiesForImage())
        return  properties.get(PhotoPropterties.self)?.dateTime ??
        properties.get(TIFFImageProperties.self)?.dateTime ??
        nil
    }
    
    
    
    static func getLastModifiedDate(for url: URL) -> Date? {
        let fileManager = FileManager.default
        let attributes = try? fileManager.attributesOfItem(atPath: url.path)
        return attributes?[FileAttributeKey.creationDate] as? Date
        ?? attributes?[FileAttributeKey.modificationDate] as? Date
    }
}

extension Photo:Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(fileUrl)
        hasher.combine(dateTime)
        hasher.combine(urlAfterSorting)
    }
    
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        lhs.fileUrl == rhs.fileUrl &&
        lhs.dateTime == rhs.dateTime &&
        lhs.urlAfterSorting == rhs.urlAfterSorting
    }
}

extension Photo {
    enum FinishedType {
        case notProcessed
        case moved
        case failed
        
        var text: String {
            switch self {
            case .notProcessed:
                return "waiting"
            case .moved:
                return "✅"
            case .failed:
                return "❌"
            }
        }
    }
}

extension DateFormatter {
    static var dateFormatter = DateFormatter()
    
    static var exifFormater: DateFormatter {
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return dateFormatter
    }
    
    static var whatsappFileFormater: DateFormatter {
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "'IMG'-yyyyMMdd-"
        return dateFormatter
    }
    
    static func parseEXIFDate(from string: String?) -> Date? {
        guard let string = string else { return nil }
        return exifFormater.date(from: string)
    }
    
    static func yearString(from date: Date) -> String {
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.setLocalizedDateFormatFromTemplate("yyyy")
        return dateFormatter.string(from: date)
    }
    
    static func monthString(from date: Date) -> String {
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.setLocalizedDateFormatFromTemplate("MM")
        var dateString = dateFormatter.string(from: date)
        dateString.append("-")
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM")
        dateString.append(dateFormatter.string(from: date))
        return dateString
    }
    
    static func dayString(from date: Date) -> String {
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.setLocalizedDateFormatFromTemplate("dd")
        return dateFormatter.string(from: date)
    }
    
    static func datePath(from date: Date) -> String {
        dateFormatter.locale = Locale(identifier: "de_DE")
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return dateFormatter.string(from: date)
    }
}

struct Photo_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
