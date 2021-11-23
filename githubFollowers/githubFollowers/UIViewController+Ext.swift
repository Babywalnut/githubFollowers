//
//  UIViewController+Ext.swift
//  githubFollowers
//
//  Created by 김민성 on 2021/11/23.
//

import UIKit

extension UIViewController {
    
    func presentGithubFollwerAlertOnMainThread(title: String, message: String, buttonTitle: String) {
        DispatchQueue.main.async {
            let alertViewController = GithubFollowerAlertViewController(title: title, message: message, buttonTitle: buttonTitle)
            alertViewController.modalPresentationStyle = .overFullScreen
            alertViewController.modalTransitionStyle = .crossDissolve
            self.present(alertViewController, animated: true)
        }
    }
}
