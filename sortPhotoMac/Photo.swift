//
//  Photo.swift
//  sortPhotoMac
//
//  Created by Stefan Haßferter on 29.08.20.
//  Copyright © 2020 Stefan Haßferter. All rights reserved.
//

import Foundation
import SwiftyImageIO

struct Photo {
    let fileUrl: URL
    let dateTime: Date?

    internal init(fileUrl: URL) {
        self.fileUrl = fileUrl
        dateTime = DateFormatter.parseEXIFDate(from: Photo.loadDateString(for: fileUrl))
            ?? Photo.getLastModifiedDate(for: fileUrl)
    }


    static func loadDateString(for url: URL) -> String? {
        let source = ImageSource(url: url, options: nil)
        guard let properties = source?.propertiesForImage() else {
            return nil;
        }

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

extension DateFormatter {
    static var exifFormater: DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "de_DE") // set locale to reliable US_POSIX
    dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
    return dateFormatter
    }

    static func parseEXIFDate(from string: String?) -> Date? {
        guard let string = string else { return nil }
        return exifFormater.date(from: string)
    }
}


//2015:07:09 18:43:04
