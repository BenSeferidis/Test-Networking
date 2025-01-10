//
//  NetworkLogger.swift
//  Networking
//
//  Created by Ben Seferidis on 10/1/25.
//

import os
import Foundation

actor NetworkLogger: Sendable {
    
    static var isLoggingEnabled = true /// Add a flag to enable/disable logging

    enum ResponseLogType {
        case success
        case failure
    }
    
    enum RequestResponseLogKey: String {
        case duration           = "⏳ DURATION"
        case url                = "🌎 URL"
        case method             = "🎛️ METHOD"
        case requestHeaders     = "🗄️ REQUEST HEADERS"
        case requestBody        = "🗃️ BODY"
        case statusCode         = "💡 STATUS CODE"
        case responseHeaders    = "📃 RESPONSE HEADERS"
        case responseJSON       = "📦 RESPONSE"
        
        static var list: [RequestResponseLogKey] {
            [.duration,
             .url,
             .method,
             .requestHeaders,
             .requestBody,
             .statusCode,
             .responseHeaders,
             .responseJSON]
        }
    }
    
    // MARK: - Public Methods
    
    static func log(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil, request: URLRequest? = nil, duration: TimeInterval? = nil) {
        guard isLoggingEnabled else { return }
        
        var message = "🚀 Request Started...\n\n"
        message += "\(getStatusDescription(for: error))\n"
        
        for logKey in RequestResponseLogKey.list {
            switch logKey {
            case .duration:
                if let duration {
                    let durationString = "\(String(format: "%.2f", duration * 1000))ms"
                    message += getLogStringPart(for: logKey.rawValue, and: durationString)
                }
            case .url:
                message += getLogStringPart(for: logKey.rawValue, and: request?.url?.absoluteString)
            case .method:
                message += getLogStringPart(for: logKey.rawValue, and: request?.httpMethod)
            case .requestHeaders:
                message += getLogStringPart(for: logKey.rawValue, and: request?.allHTTPHeaderFields)
            case .requestBody:
                if let bodyData = request?.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
                    let uuid = UUID().uuidString.split(separator: "-").first!
                    let body = "↙️ ID: \(uuid)\n\(bodyString)\n ↖️ ID: \(uuid)"
                    message += getLogStringPart(for: logKey.rawValue, and: body)
                }
            case .statusCode:
                if let httpResponse = response as? HTTPURLResponse {
                    message += getLogStringPart(for: logKey.rawValue, and: httpResponse.statusCode)
                }
            case .responseHeaders:
                if let httpResponse = response as? HTTPURLResponse {
                    message += getLogStringPart(for: logKey.rawValue, and: httpResponse.allHeaderFields)
                }
            case .responseJSON:
                if let data = data {
                    let uuid = UUID().uuidString.split(separator: "-").first!
                    var responseString: String?
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data), let jsonData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted), let jsonString = String(data: jsonData, encoding: .utf8) {
                        responseString = "↙️ ID: \(uuid)\n\(jsonString)\n ↖️ ID: \(uuid)"
                    } else {
                        let string = String(decoding: data, as: UTF8.self)
                        responseString = "↙️ ID: \(uuid)\n\(string)\n ↖️ ID: \(uuid)"
                    }
                    message += getLogStringPart(for: logKey.rawValue, and: responseString)
                }
            }
        }
        
        if let error = error {
            let errorString = "♦️ \(error)"
            message += getLogStringPart(for: "ERROR", and: errorString)
        }
        
        message += "\n🏁 Request completed.\n"
        
        /// Log the message
        log(message: message)
    }
    
    // MARK: - Private Methods
    
    private static func getStatusDescription(for error: Error?) -> String {
        if error == nil {
            return "✅ SUCCESS"
        } else {
            return "❌ FAILURE"
        }
    }
    
    private static func getLogStringPart(for option: String, and value: Any?) -> String {
        composeKeyValueString(for: option, and: value)
    }
    
    private static func composeKeyValueString(for option: String, and object: Any?) -> String {
        // Get longest key string length
        let longestOptionRawLength = getLongestOptionStringLength()
        // Create key string
        let key = stringWithAddedSpacesToMatchLenghtOf(longestOptionRawLength, forString: option)
        // Get value string
        let value = getString(forOptionalValue: object)
        // ...........
        return getFormattedKeyValueString(for: key, and: value)
    }
    
    private static func getDictionaryValuesMargin() -> Int {
        // Key to value padding
        let padding = 4
        // Margin
        let margin = padding + getLongestOptionStringLength()
        // ...........
        return margin
    }
    
    private static func getLongestOptionStringLength() -> Int {
        // Declare maximum length
        var maxLength = 0
        // Iterate log key list
        for option in RequestResponseLogKey.list {
            // Get max length
            maxLength = max(option.rawValue.count, maxLength)
        }
        // Margin
        let margin = 1
        // Final length
        let finalLength = margin + maxLength
        // ...........
        return finalLength
    }
    
    public static func stringWithAddedSpacesToMatchLenghtOf(_ stringLength: Int, forString initialString: String) -> String {
        // Get initial string length
        let initialStringLength = initialString.count
        // Check length
        guard initialStringLength < stringLength else {
            return initialString
        }
        // Get length difference
        let lengthDifference = stringLength - initialStringLength
        // Final string with spaces
        let finalString = initialString.addSpaces(lengthDifference, position: .front)
        // ...........
        return finalString
    }
    
    public static func getFormattedKeyValueString(for key: String, and value: String, withLeftPaggingSize leftPaggingSize: Int = 0, isPrintingNewLine: Bool = true) -> String {
        // Add margin string
        let margin = leftPaggingSize > 0 ? "".addSpaces(leftPaggingSize, position: .back) : ""
        // Final string
        let finalString = "\(isPrintingNewLine ? "\n" : "")\(margin)\(key) ▪️ \(value)"
        // ...........
        return finalString
    }
    
    public static func getFormattedDictionaryString(dict: [AnyHashable: Any]?, withLeftPaggingSize leftPaggingSize: Int = 0) -> String {
        // Check dictionary
        guard let dict = dict, !dict.isEmpty else {
            return ""
        }
        // Declare result string
        var resultString = ""
        // Iterate dictionary items
        for (index, item) in dict.enumerated() {
            // If first item them padding is zero
            let leftPaggingSize = index == 0 ? 0 : leftPaggingSize
            // Is printing ne line
            let isPrintingNewLine = index == 0 ? false : true
            // ...........
            resultString += getFormattedKeyValueString(for: "\(item.key)", and: "\(item.value)", withLeftPaggingSize: leftPaggingSize, isPrintingNewLine: isPrintingNewLine)
        }
        // ...........
        return resultString
    }
    
    static func getString<T>(forOptionalValue value: T?, substitute: String? = nil) -> String {
        let emptyStringSymbol = substitute ?? "◯"
        guard let value = value, let convertableValue = value as? CustomStringConvertible else {
            return emptyStringSymbol
        }
        let valueString = "\(convertableValue)"
        guard !valueString.isEmpty else {
            return emptyStringSymbol
        }
        return valueString
    }
    
    private static func log(message: String) {
        // Implement logging mechanism here, e.g., print to console or log to a file.
        print(message)
    }
}


extension Data {
    var prettyPrintedJSONString: NSString? {
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        return prettyPrintedString
    }
}

extension String {
    
    enum AdditionalSpacesPosition {
        case front
        case back
    }
    
    func addSpaces(_ numberOfSpaces: Int, position: AdditionalSpacesPosition) -> String {
        // Check number of spaces
        guard numberOfSpaces > 0 else {
            print("numberOfSpaces <= 0")
            return self
        }
        // Create spaces
        let spaces = String(repeating: " ", count: numberOfSpaces)
        // Handle position
        switch position {
        case .front:
            return spaces + self
            // ...........
        case .back:
            return self + spaces
        }
    }
}
