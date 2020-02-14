//
//  File.swift
//  CotterIOS
//
//  Created by Albert Purnama on 2/3/20.
//

import Foundation

public typealias Callback = (String) -> Void

public class CotterAPIService {
    // shared cotterAPI service to be used anywhere later
    // when you want to use the APIService, do CotterAPIService.shared.<function-name>
    public static let shared = CotterAPIService()
    
    // defaultCb is the default callback function for token
    public static func defaultCb(token:String) -> Void{
        print(token)
        return
    }
    
    private let urlSession = URLSession.shared
    var baseURL: URL?
    var path: String?
    var apiSecretKey: String=""
    var apiKeyID: String=""
    var userID: String?
    
    private init(){}
    
    private let jsonDecoder: JSONDecoder = {
       let jsonDecoder = JSONDecoder()
       jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
       let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyy-mm-dd"
       jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
       return jsonDecoder
    }()
    
    public func http(method:String, path:String, data: [String:Any]?, successCb: @escaping Callback = defaultCb, errCb: @escaping Callback = defaultCb) {
        // set url path
        let urlString = self.baseURL!.absoluteString + path
        let url = URL(string:urlString)!
        
        // create request
        var request = URLRequest(url:url)
        
        // fill the required request headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiSecretKey, forHTTPHeaderField: "API_SECRET_KEY")
        request.setValue(self.apiKeyID, forHTTPHeaderField: "API_KEY_ID")
        request.httpMethod = method
        
        // fill in the body with json if exist
        if data != nil {
            request.httpBody = try? JSONSerialization.data(withJSONObject: data!)
        }
        
        // start http request
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else { // check for fundamental networking error
                // TODO: error handling
                print("error", error ?? "Unknown error")
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {   // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("response = \(response)")
                print("errMsg = \(String(decoding: data, as:UTF8.self))")
                
                // error handling
                DispatchQueue.main.async{
                    errCb("statusCode should be 2xx, but is \(response.statusCode)")
                }
                
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            
            // if it reaches this point, that means the http request is successful
            DispatchQueue.main.async{
                successCb(responseString!)
            }
        }
        task.resume()
    }
    
    public func auth(
        data: [String: Any]?,
        cb: @escaping (Bool) -> Void
    ) {
        // set url path
        let urlString = self.baseURL!.absoluteString + "/event/create"
        let url = URL(string:urlString)!
        
        // create request
        var request = URLRequest(url:url)
        
        // fill the required request headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(self.apiSecretKey, forHTTPHeaderField: "API_SECRET_KEY")
        request.setValue(self.apiKeyID, forHTTPHeaderField: "API_KEY_ID")
        
        // always a POST request
        request.httpMethod = "POST"
        
        // fill in the body with json if exist
        if data != nil {
            request.httpBody = try? JSONSerialization.data(withJSONObject: data!)
        }
        
        // start http request
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard let data = data,
                let response = response as? HTTPURLResponse,
                error == nil else { // check for fundamental networking error
                // TODO: error handling
                print("error", error ?? "Unknown error")
                return
            }
            
            guard (200 ... 299) ~= response.statusCode else {   // check for http errors
                print("statusCode should be 2xx, but is \(response.statusCode)")
                print("errorMsg = \(String(decoding: data, as: UTF8.self))")
                print("response = \(response)")
                
                // error handling
                DispatchQueue.main.async{
                    // handle failed authentication
                    cb(false)
                }
                
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")
            
            // if it reaches this point, that means the http request is successful
            DispatchQueue.main.async{
                // handle success authentication
                cb(true)
            }
        }
        task.resume()
    }
    
    public func registerUser(
        userID: String,
        successCb: @escaping Callback,
        errCb: @escaping Callback
    ) {
        // register the user
        let method = "POST"
        let path = "/user/create"
        let data = [
            "client_user_id": userID
        ]
        
        self.http(
            method: method,
            path: path,
            data: data,
            successCb: successCb,
            errCb: errCb
        )
    }
    
    public func enrollUserPin(
        code: String,
        successCb: @escaping Callback,
        errCb: @escaping Callback
    ) {
        let method = "PUT"
        let path = "/user/" + CotterAPIService.shared.userID!
        let data: [String: Any] = [
            "method": "PIN",
            "enrolled": true,
            "code": code
        ]
        
        self.http(
            method: method,
            path: path,
            data: data,
            successCb: successCb,
            errCb: errCb
        )
    }
    
    public func updateUserPin(
        oldCode: String,
        newCode: String,
        successCb: @escaping Callback,
        errCb: @escaping Callback
    ) {
        let method = "PUT"
        let path = "/user/" + CotterAPIService.shared.userID!
        let data: [String: Any] = [
            "method": "PIN",
            "enrolled": true,
            "current_code": oldCode,
            "code": newCode,
            "change_code": true
        ]
        
        self.http(
            method: method,
            path: path,
            data: data,
            successCb: successCb,
            errCb: errCb
        )
    }
}
