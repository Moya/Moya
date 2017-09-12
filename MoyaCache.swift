//
//  MoyaCache.swift
//  Moya
//
//  Created by tesla on 2017/9/12.
//

import Foundation

public extension MoyaProvider {
    
    let cache_queue: DispatchQueue = DispatchQueue(label: "moya_cache", attributes: .concurrent)
    
    func saveResponseToCache( _ target: TargetType, _ response: HTTPURLResponse) {
        guard target.cacheTimeInSecondes > 0 && response.statusCode == 200 else { return }
        switch target.task {
        case .requestParameters(_):
            break
        default:
            return
        }
        let filePath = cacheFilePath(target: target)
        if !NSKeyedArchiver.archiveRootObject(response, toFile: filePath) {
            print("Moya Error: Cache request:\(target.path) failed")
        }
    }
    
    func loadCache(withTarget target: TargetType) -> HTTPURLResponse? {
        let filePath = cacheFilePath(target: target)
        guard FileManager.default.fileExists(atPath: filePath, isDirectory: nil) else { return nil }
        switch target.task {
        case .requestParameters(_):
            break
        default:
            return nil
        }
        guard validateCache(target: target) else {
            removeFile(atPath: filePath)
            return nil
        }
        
        let response = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? HTTPURLResponse
        
        return response
    }
    
    func removeFile(atPath path: String) {
        do {
            try FileManager.default.removeItem(at: URL(fileURLWithPath: path))
        } catch {
            print("Moya Error: remove file failed")
        }
    }
    
    func validateCache(target: TargetType) -> Bool {
        let resourcesKeys = [URLResourceKey.contentModificationDateKey]
        let filePath = cacheFilePath(target: target)
        let fileEnumrator = FileManager.default.enumerator(at: URL(fileURLWithPath: filePath), includingPropertiesForKeys: resourcesKeys)
        
        let expirationDate = Date.init(timeIntervalSinceNow: Double(target.cacheTimeInSecondes))
        guard let modifiyDate = fileEnumrator?.fileAttributes?[FileAttributeKey.modificationDate] as? Date else { return false }
        return expirationDate.timeIntervalSince1970 > modifiyDate.timeIntervalSince1970
    }
    
    func cacheBasePath() -> String {
        let pathOfCache = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!
        let path = pathOfCache.appending("MoayNetworkCache")
        createDirectoryIfNeed(path: path)
        return path
    }
    
    func createDirectoryIfNeed(path: String) {
        var isDir: ObjCBool = ObjCBool(false)
        if !FileManager.default.fileExists(atPath: path, isDirectory: &isDir) {
            createDirectory(atPath: path)
        } else {
            if !isDir.boolValue {
                removeFile(atPath: path)
                createDirectory(atPath: path)
            }
        }
    }
    
    func createDirectory(atPath path: String) {
        if !FileManager.default.createFile(atPath: path, contents: nil, attributes: nil) {
            print("Moya Error: createDirectory Ffailed")
        }
    }
    
    func cacheFilePath(target: TargetType) -> String {
        let fileName = cacheFileName(target: target)
        let basePath = cacheBasePath()
        return basePath + "\\\(fileName)"
    }
    
    func cacheFileName(target: TargetType) -> String {
        var paramsString: String
        switch target.task {
        case .requestParameters(let params, _):
            paramsString = params.description
        default:
            paramsString = ""
        }
        let requestInfo: String = target.baseURL.absoluteString + target.path + target.method.rawValue + paramsString
        let fileName = requestInfo.md5() ?? ""
        return fileName
    }
}
