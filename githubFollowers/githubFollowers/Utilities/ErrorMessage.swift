//
//  ErrorMessage.swift
//  githubFollowers
//
//  Created by 김민성 on 2021/12/22.
//

import Foundation

enum GithubFollowerError: String, Error {
    case invalidUsername = "This username created an invalid request. Please try again."
    case unableToComplete = "Unable to commplete your request. Please check your internet connection."
    case invalidResponse = "Invalid response from the server. Please try again."
    case invalidData = "The data received from the server was invalid. Please try again."
}
