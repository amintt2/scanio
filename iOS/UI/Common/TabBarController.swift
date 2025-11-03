//
//  TabBarController.swift
//  Aidoku
//
//  Created by Skitty on 7/26/25.
//

import SwiftUI

class TabBarController: UITabBarController {
    private lazy var libraryProgressView = CircularProgressView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))

    // Onboarding
    private var onboardingHostingController: UIHostingController<OnboardingWelcomeView>?
    private var overlayHostingController: UIHostingController<InteractiveOnboardingOverlay>?

    private lazy var libraryRefreshAccessory: UIView = {
        let view = UIView()

        let label = UILabel()
        label.text = NSLocalizedString("REFRESHING_LIBRARY")
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        libraryProgressView.radius = 12
        libraryProgressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(libraryProgressView)

        if #unavailable(iOS 26) {
            // add styling for older versions without the bottom accessory view
            let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
            backgroundView.layer.cornerRadius = 48 / 2
            backgroundView.layer.borderColor = UIColor.quaternarySystemFill.cgColor
            backgroundView.layer.borderWidth = 1
            backgroundView.clipsToBounds = true
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            view.insertSubview(backgroundView, at: 0)

            NSLayoutConstraint.activate([
                backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
                backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: libraryProgressView.leadingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.heightAnchor.constraint(equalToConstant: 48),

            libraryProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            libraryProgressView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            libraryProgressView.widthAnchor.constraint(equalToConstant: 20),
            libraryProgressView.heightAnchor.constraint(equalToConstant: 20)
        ])

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        let libraryViewController = SwiftUINavigationController(rootViewController: LibraryViewController())
        let browseViewController = UINavigationController(rootViewController: BrowseViewController())
        let searchViewController = UINavigationController(rootViewController: SearchViewController())

        let historyPath = NavigationCoordinator(rootViewController: nil)
        let historyHostingController = UIHostingController(rootView: HistoryView()
                                                            .environmentObject(historyPath))
        historyPath.rootViewController = historyHostingController
        let historyViewController = UINavigationController(rootViewController: historyHostingController)

        let settingsPath = NavigationCoordinator(rootViewController: nil)
        let settingsHostingController = UIHostingController(rootView: SettingsView()
                                                                .environmentObject(settingsPath))
        settingsPath.rootViewController = settingsHostingController
        let settingsViewController = UINavigationController(rootViewController: settingsHostingController)

        libraryViewController.navigationBar.prefersLargeTitles = true
        browseViewController.navigationBar.prefersLargeTitles = true
        historyViewController.navigationBar.prefersLargeTitles = true
        searchViewController.navigationBar.prefersLargeTitles = true
        settingsViewController.navigationBar.prefersLargeTitles = true

        if #available(iOS 26.0, *) {
            let searchTab = UISearchTab { _ in
                searchViewController
            }
            searchTab.automaticallyActivatesSearch = true
            tabs = [
                UITab(
                    title: NSLocalizedString("LIBRARY"),
                    image: UIImage(systemName: "books.vertical.fill"),
                    identifier: "0"
                ) { _ in
                    libraryViewController
                },
                UITab(
                    title: NSLocalizedString("BROWSE"),
                    image: UIImage(systemName: "globe"),
                    identifier: "1"
                ) { _ in
                    browseViewController
                },
                UITab(
                    title: NSLocalizedString("HISTORY"),
                    image: UIImage(systemName: "clock.fill"),
                    identifier: "2"
                ) { _ in
                    historyViewController
                },
                UITab(
                    title: NSLocalizedString("SETTINGS"),
                    image: UIImage(systemName: "gear"),
                    identifier: "3"
                ) { _ in
                    settingsViewController
                },
                searchTab
            ]
        } else {
            libraryViewController.tabBarItem = UITabBarItem(
                title: NSLocalizedString("LIBRARY", comment: ""),
                image: UIImage(systemName: "books.vertical.fill"),
                tag: 0
            )
            browseViewController.tabBarItem = UITabBarItem(
                title: NSLocalizedString("BROWSE", comment: ""),
                image: UIImage(systemName: "globe"),
                tag: 1
            )
            historyViewController.tabBarItem = UITabBarItem(
                tabBarSystemItem: .history,
                tag: 2
            )
            searchViewController.tabBarItem = UITabBarItem(
                tabBarSystemItem: .search,
                tag: 3
            )
            settingsViewController.tabBarItem = UITabBarItem(
                title: NSLocalizedString("SETTINGS", comment: ""),
                image: UIImage(systemName: "gear"),
                tag: 4
            )
            viewControllers = [
                libraryViewController,
                browseViewController,
                historyViewController,
                searchViewController,
                settingsViewController
            ]
        }

        let updateCount = UserDefaults.standard.integer(forKey: "Browse.updateCount")
        browseViewController.tabBarItem.badgeValue = updateCount > 0 ? String(updateCount) : nil

        // Setup onboarding notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRestartOnboarding),
            name: NSNotification.Name("RestartOnboarding"),
            object: nil
        )

        // Set tab bar controller reference for onboarding
        OnboardingManager.shared.tabBarController = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Check if this is first launch and show onboarding
        if !OnboardingManager.shared.hasCompletedTutorial && !OnboardingManager.shared.isActive {
            // Delay to ensure view is fully loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showOnboardingWelcome()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension TabBarController {
    func showLibraryRefreshView() {
        libraryProgressView.setProgress(value: 0, withAnimation: false)

        if #available(iOS 26.0, *) {
            setBottomAccessory(.init(contentView: libraryRefreshAccessory), animated: true)
        } else {
            libraryRefreshAccessory.layer.opacity = 0
            view.insertSubview(libraryRefreshAccessory, belowSubview: tabBar)
            UIView.animate(withDuration: 0.5) {
                self.libraryRefreshAccessory.layer.opacity = 1
            }
        }
    }

    func setLibraryRefreshProgress(_ progress: Float) {
        libraryProgressView.setProgress(value: progress, withAnimation: true)
    }

    func hideAccessoryView() {
        if #available(iOS 26.0, *) {
            setBottomAccessory(nil, animated: true)
        } else {
            UIView.animate(withDuration: 0.5) {
                self.libraryRefreshAccessory.layer.opacity = 0
            } completion: { _ in
                self.libraryRefreshAccessory.removeFromSuperview()
            }
        }
    }

    override func viewDidLayoutSubviews() {
        if #unavailable(iOS 26.0) {
            let height: CGFloat = 48
            let padding: CGFloat = 16

            libraryRefreshAccessory.frame = CGRect(
                x: tabBar.frame.origin.x + view.safeAreaInsets.left + padding,
                y: tabBar.frame.origin.y - height - padding / 2,
                width: tabBar.frame.width - padding * 2 - view.safeAreaInsets.left - view.safeAreaInsets.right,
                height: height
            )
        }
    }
}

// MARK: - Keyboard Shortcuts
extension TabBarController {
    override var keyCommands: [UIKeyCommand]? {
        tabBar.items?.enumerated().map { index, item in
            UIKeyCommand(
                title: item.title ?? "Tab \(index + 1)",
                action: #selector(selectTab),
                input: "\(index + 1)",
                modifierFlags: .shiftOrCommand,
                alternates: [],
                attributes: [],
                state: .off
            )
        }
    }

    @objc private func selectTab(sender: UIKeyCommand) {
        guard
            let input = sender.input,
            let newIndex = Int(input),
            newIndex >= 1 && newIndex <= (tabBar.items?.count ?? 0)
        else { return }
        selectedIndex = newIndex - 1
    }

    override var canBecomeFirstResponder: Bool { true }
}

// MARK: - Onboarding
extension TabBarController {
    @objc private func handleRestartOnboarding() {
        print("🎓 [TabBarController] Handling restart onboarding notification")
        // Dismiss settings if open
        dismiss(animated: true) { [weak self] in
            self?.showOnboardingWelcome()
        }
    }

    private func showOnboardingWelcome() {
        print("🎓 [TabBarController] Showing onboarding welcome")
        let welcomeView = OnboardingWelcomeView(
            onStart: { [weak self] in
                print("🎓 [TabBarController] User started tutorial")
                self?.onboardingHostingController?.dismiss(animated: true) {
                    OnboardingManager.shared.startTutorial()
                    self?.showOnboardingOverlay()
                }
            },
            onSkip: { [weak self] in
                print("🎓 [TabBarController] User skipped tutorial")
                self?.onboardingHostingController?.dismiss(animated: true)
                OnboardingManager.shared.skipTutorial()
            }
        )

        onboardingHostingController = UIHostingController(rootView: welcomeView)
        onboardingHostingController?.modalPresentationStyle = .fullScreen

        if let controller = onboardingHostingController {
            present(controller, animated: true)
        }
    }

    private func showOnboardingOverlay() {
        guard OnboardingManager.shared.isActive else {
            print("🎓 [TabBarController] Onboarding not active, skipping overlay")
            return
        }

        let currentStep = OnboardingManager.shared.currentStep
        guard currentStep < OnboardingManager.shared.steps.count else {
            print("🎓 [TabBarController] All steps completed")
            OnboardingManager.shared.completeTutorial()
            return
        }

        let step = OnboardingManager.shared.steps[currentStep]
        print("🎓 [TabBarController] Showing overlay for step \(currentStep): \(step.title)")

        // Navigate to the correct tab for this step
        selectedIndex = step.targetTab

        // Show overlay after navigation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let overlayView = InteractiveOnboardingOverlay(
                step: step,
                onNext: { [weak self] in
                    print("🎓 [TabBarController] User tapped Next")
                    self?.hideOnboardingOverlay()
                    OnboardingManager.shared.nextStep()

                    // Show next step or complete
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.showOnboardingOverlay()
                    }
                },
                onSkip: { [weak self] in
                    print("🎓 [TabBarController] User skipped tutorial")
                    self?.hideOnboardingOverlay()
                    OnboardingManager.shared.skipTutorial()
                }
            )

            self?.overlayHostingController = UIHostingController(rootView: overlayView)
            self?.overlayHostingController?.view.backgroundColor = .clear
            self?.overlayHostingController?.modalPresentationStyle = .overFullScreen

            if let controller = self?.overlayHostingController {
                self?.present(controller, animated: true)
            }
        }
    }

    private func hideOnboardingOverlay() {
        overlayHostingController?.dismiss(animated: true)
        overlayHostingController = nil
    }
}
