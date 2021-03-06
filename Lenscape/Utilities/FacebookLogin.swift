//
//  FacebookLogin.swift
//  Lenscape
//
//  Created by TAWEERAT CHAIMAN on 6/3/2561 BE.
//  Copyright © 2561 Lenscape. All rights reserved.
//

import Foundation
import FacebookLogin
import PromiseKit
import FBSDKLoginKit

class FacebookLogin {
    func login(vc: UIViewController) -> Promise<String>{
        return Promise { seal in
            let loginManager = LoginManager()
            loginManager.logOut()
            loginManager.logIn(readPermissions: [.publicProfile, .email], viewController: vc) { loginResult in
                switch loginResult {
                case .failed(let error):
                    seal.reject(error)
                case .cancelled:
                    seal.reject(NSError(domain: "User cancelled login.", code: 0, userInfo: nil))
                case .success(let accessToken):
                    let token = accessToken.token.authenticationToken
                    seal.fulfill(token)
                }
            }
        }
    }
    
    func getFBUserData() -> Promise<[String: Any]>{
        let params = [
            "fields":"id, name, picture.type(large), email"
        ]
        return Promise { seal in
            let currentToken = FBSDKAccessToken.current()
            if(currentToken != nil){
                FBSDKGraphRequest(graphPath: "me", parameters: params).start{
                    (connection, result, error) -> Void in
                    if (error == nil){
                        var user = UserController.convertFBtoNormal(facebookUserData: result as! [String: AnyObject])
                        user["token"] = FBSDKAccessToken.current().tokenString
                        seal.fulfill(user)
                    } else {
                        seal.reject(error!)
                    }
                }
            }
        }
    }
    
    func logOut(){
        let loginManager = LoginManager()
        loginManager.logOut()
    }
}
