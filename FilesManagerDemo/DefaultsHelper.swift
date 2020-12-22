//
//  defaultsHelper.swift
//  ClassMate
//
//  Created by אורי האופטמן on 21/05/2020.
//  Copyright © 2020 אורי האופטמן. All rights reserved.
//

import Foundation
import UIKit

protocol ObjectSavable {
    func setToObject<Object>(_ object: Object, forKey: String) throws where Object: Encodable
    func getToObject<Object>(forKey: String, castTo type: Object.Type) throws -> Object where Object: Decodable
}

extension UserDefaults: ObjectSavable {
    func setToObject<Object>(_ object: Object, forKey: String) throws where Object: Encodable {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            set(data, forKey: forKey)
        } catch {
            throw ObjectSavableError.unableToEncode
        }
    }
    
    func getToObject<Object>(forKey: String, castTo type: Object.Type) throws -> Object where Object: Decodable {
        guard let data = data(forKey: forKey) else { throw ObjectSavableError.noValue }
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(type, from: data)
            return object
        } catch {
            throw ObjectSavableError.unableToDecode
        }
    }
}

enum ObjectSavableError: String, LocalizedError {
    case unableToEncode = "Unable to encode object into data"
    case noValue = "No data object found for the given key"
    case unableToDecode = "Unable to decode object into given type"
    
    var localizedDescription: String? {
        switch self {
        case .unableToEncode:
            return NSLocalizedString("לא ניתן להמיר את המידע לנתונים", comment: "שגיאה. מקור: Unable to encode object into data")
        case .noValue:
            return NSLocalizedString("לא נמצא מידע בערך הנתון.", comment: "שגיאה. מקור: No data found for the given value")
        case .unableToDecode:
            return NSLocalizedString("לא ניתן להמיר את הנתונים למידע", comment: "שגיאה. מקור: Unable to decode object into data")
        }
    }
}
