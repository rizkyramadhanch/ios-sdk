//
//  Constants.swift
//  Cotter
//
//  Created by Albert Purnama on 2/29/20.
//

import Foundation

public struct CotterConstants {
    // MARK: - List of Verification Methods
    public static let MethodPIN = "PIN"
    public static let MethodBiometric = "BIOMETRIC"
    
    // MARK: - List of Sending Methods
    public static let MethodEmail = "EMAIL"
    public static let MethodPhone = "PHONE"
    public static let MethodTrustedDevice = "TRUSTED_DEVICE"
}

public struct CotterEvents {
    // MARK: - List of events
    public static let EnrollNewTrustedDevice = "ENROLL_NEW_TRUSTED_DEVICE"
}
