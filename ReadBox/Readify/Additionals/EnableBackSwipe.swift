//
//  BackSwipe.swift
//  ReadBox
//
//  Created by Macbook Pro on 05.08.2025.
//

import SwiftUI

struct EnableSwipeBack: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        SwipeBackController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        (uiViewController as? SwipeBackController)?.enableSwipeBack()
    }

    final class SwipeBackController: UIViewController {
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            enableSwipeBack()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            enableSwipeBack()
        }

        func enableSwipeBack() {
            DispatchQueue.main.async { [weak self] in
                guard let nav = self?.navigationController else { return }

                nav.interactivePopGestureRecognizer?.isEnabled = true
                nav.interactivePopGestureRecognizer?.delegate = nil
            }
        }
    }
}
