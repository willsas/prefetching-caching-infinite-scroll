//
//  MainTabBarController.swift
//  prefetching-caching-infinite-scroll

import UIKit

final class MainTabBarController: UITabBarController {

    convenience init() {
        self.init(tabs: [
            UITab(
                title: "Current",
                image: .init(
                    systemName: "rectangle.stack.fill",
                    withConfiguration: UIImage.SymbolConfiguration.preferringMulticolor()
                ),
                identifier: String(describing: CurrentScrollViewController.self),
                viewControllerProvider: { _ in CurrentScrollViewController() }
            ),
            UITab(
                title: "Improved",
                image: .init(
                    systemName: "sparkles.rectangle.stack.fill",
                    withConfiguration: UIImage.SymbolConfiguration.preferringMulticolor()
                ),
                identifier: String(describing: ImprovedScrollViewController.self),
                viewControllerProvider: { _ in ImprovedScrollViewController() }
            )
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UITabBar.appearance().tintColor = UIColor.red
    }
}
