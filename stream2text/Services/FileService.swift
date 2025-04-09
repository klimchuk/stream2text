//
//  FileService.swift
//  stream2text
//
//  Created by Nikolay Klimchuk on 3/21/24.
//

import Foundation

class FileService {
    enum Error: Swift.Error {
        case fileAlreadyExists
        case invalidDirectory
        case writtingFailed
        case fileNotExists
        case readingFailed
    }
    let fileManager: FileManager
    
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    func read(fileNamed: String) throws -> Data {
       guard let url = makeURL(forFileNamed: fileNamed) else {
           throw Error.invalidDirectory
       }
       /*guard fileManager.fileExists(atPath: url.absoluteString) else {
           throw Error.fileNotExists
       }*/
       do {
           return try Data(contentsOf: url)
       } catch {
           debugPrint(error)
           throw Error.readingFailed
       }
   }
    
    func save(fileNamed: String, data: Data) throws {
        guard let url = makeURL(forFileNamed: fileNamed) else {
            throw Error.invalidDirectory
        }
        if fileManager.fileExists(atPath: url.path) {
            //throw Error.fileAlreadyExists
            try? fileManager.removeItem(at: url)
        }
        do {
            try data.write(to: url)
        } catch {
            debugPrint(error)
            throw Error.writtingFailed
        }
    }
    
    func delete(fileNamed: String) throws
    {
        guard let url = makeURL(forFileNamed: fileNamed) else {
            throw Error.invalidDirectory
        }
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
    
    private func makeURL(forFileNamed fileName: String) -> URL? {
        guard let url = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        try? fileManager.createDirectory (at: url, withIntermediateDirectories: true, attributes: nil)
        return url.appendingPathComponent(fileName)
    }    
}
