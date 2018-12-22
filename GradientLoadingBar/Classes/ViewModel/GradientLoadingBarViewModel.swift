//
//  GradientLoadingBarViewModel.swift
//  GradientLoadingBar
//
//  Created by Felix Mau on 12/26/17.
//  Copyright © 2017 Felix Mau. All rights reserved.
//

import Foundation
import Observable

/// The `GradientLoadingBarViewModel` class is responsible for the visibility state of the gradient view.
class GradientLoadingBarViewModel {
    // MARK: - Types

    /// This struct contains all infomation that are required for an animated visibility update
    /// of the loading bar.
    struct AnimatedVisibilityUpdate: Equatable {
        /// Initialies the struct with values set to zero / hidden.
        static let immediatelyHidden = AnimatedVisibilityUpdate(duration: 0.0, isHidden: true)

        /// The duration for the visibility update.
        let duration: TimeInterval

        /// Boolean flag, whether the view should be hidden.
        let isHidden: Bool
    }

    // MARK: - Public properties

    var isVisible: ImmutableObservable<AnimatedVisibilityUpdate> {
        return isVisibleSubject
    }

    var superview: ImmutableObservable<UIView?> {
        return superviewSubject
    }

    // MARK: - Private properties

    /// Boolean flag determinating whether gradient view is currently visible.
    private let isVisibleSubject: Observable<AnimatedVisibilityUpdate> = Observable(.immediatelyHidden)

    /// Boolean flag determinating whether gradient view is currently visible.
    private let superviewSubject: Observable<UIView?> = Observable(nil)

    /// Configuration with durations for each animation.
    private let durations: Durations

    // MARK: - Dependencies

    private let sharedApplication: UIApplicationProtocol
    private let notificationCenter: NotificationCenter

    // MARK: - Constructor

    init(superview: UIView?,
         durations: Durations,
         sharedApplication: UIApplicationProtocol = UIApplication.shared,
         notificationCenter: NotificationCenter = .default) {
        self.durations = durations
        self.sharedApplication = sharedApplication
        self.notificationCenter = notificationCenter

        if let superview = superview {
            // We have a valid key window » Use it as superview.
            superviewSubject.value = superview
        } else {
            // The initializer is called from `appDelegate`, where the key window is not available yet.
            // Therefore we setup an observer to inform the listeners when it's ready.
            notificationCenter.addObserver(self,
                                           selector: #selector(didReceiveUIWindowDidBecomeKeyNotification(_:)),
                                           name: UIWindow.didBecomeKeyNotification,
                                           object: nil)
        }
    }

    // MARK: - Private methods

    @objc private func didReceiveUIWindowDidBecomeKeyNotification(_: Notification) {
        guard let keyWindow = sharedApplication.keyWindow else { return }

        // Prevent informing the listeners multiple times.
        notificationCenter.removeObserver(self)

        // Now that we have a valid key window, we can use it as superview.
        superviewSubject.value = keyWindow
    }

    // MARK: - Public methods

    /// Fades in the gradient loading bar.
    func show() {
        isVisibleSubject.value = AnimatedVisibilityUpdate(duration: durations.fadeIn,
                                                          isHidden: false)
    }

    /// Fades out the gradient loading bar.
    func hide() {
        isVisibleSubject.value = AnimatedVisibilityUpdate(duration: durations.fadeOut,
                                                          isHidden: true)
    }

    /// Toggle visiblity of gradient loading bar.
    func toggle() {
        if isVisible.value.isHidden {
            show()
        } else {
            hide()
        }
    }
}

// MARK: - Helper

/// This allows mocking `UIApplication` in tests.
protocol UIApplicationProtocol: AnyObject {
    var keyWindow: UIWindow? { get }
}

extension UIApplication: UIApplicationProtocol {}
