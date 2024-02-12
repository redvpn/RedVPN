// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class OnboardingViewController: UIPageViewController {

    let pageCount = 3
    private var pages = [UIViewController]()

    let pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.frame = CGRect()
        pageControl.currentPageIndicatorTintColor = UIColor.systemBlue
        pageControl.pageIndicatorTintColor = UIColor.lightBlue
        pageControl.currentPage = 0
        pageControl.transform = CGAffineTransform(scaleX: 1, y: 1)
        pageControl.isUserInteractionEnabled = false
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        return pageControl
    }()

    let nextButton: UIButton = {
        let nextButton = UIButton()
        nextButton.layer.cornerRadius = 54 / 2
        nextButton.clipsToBounds = true
        nextButton.backgroundColor = UIColor.blueBright
        nextButton.tintColor = UIColor.white
        nextButton.setTitle(tr("onboardingNext"), for: .normal)
        nextButton.titleLabel?.font = UIFont(name: "SFProDisplay-Regular", size: 18.0)
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        return nextButton
    }()

    var onNextButtonTouched: (() -> Void)?

    @objc func nextButtonTouched(_ sender: UIButton) {
        onNextButtonTouched?()
    }

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .backgroundDark

        nextButton.addTarget(self, action: #selector(nextButtonTouched), for: .touchUpInside)
        self.dataSource = self
        self.delegate = self

        setupPages()
        setupViews()
    }

    private func setupPages() {
        for i in 0...pageCount - 1 {
            let page = OnboardingPageViewController(image: getPageImage(index: i), title: getPageTitle(index: i))
            pages.append(page)
        }

        setViewControllers([pages[0]], direction: .reverse, animated: false, completion: nil)
        pageControl.numberOfPages = pageCount
    }

    private func setupViews() {

        view.addSubview(pageControl)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: view.frame.height < 600 ? -28.0 : -48.0),

            nextButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextButton.heightAnchor.constraint(equalToConstant: 54.0),
            nextButton.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: view.frame.height < 600 ? -20.0 : -40.0),
            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 25.0),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -25.0)
        ])
    }

    private func getPageImage(index: Int) -> String {
        switch index {
        case 0:
            return "Encryption"
        case 1:
            return "Communication"
        case 2:
            return "Internet_of_Things"
        default:
            return ""
        }
    }

    private func getPageTitle(index: Int) -> String {
        switch index {
        case 0:
            return tr("onboardingEncryption")
        case 1:
            return tr("onboardingFastServers")
        case 2:
            return tr("onboardingNoLogs")
        default:
            return ""
        }
    }

    private func getButtonTitle(index: Int) -> String {
        return index < pageCount - 1 ? tr("onboardingNext") : tr("onboardingComplete")
    }

    func goToNextPage(animated: Bool = true) {
        guard let currentViewController = self.viewControllers?.first else { return }
        guard let nextViewController = dataSource?.pageViewController(self, viewControllerAfter: currentViewController) else { return }
        setViewControllers([nextViewController], direction: .forward, animated: animated, completion: nil)
        pageControl.currentPage += 1
    }

    func goToPreviousPage(animated: Bool = true) {
        guard let currentViewController = self.viewControllers?.first else { return }
        guard let previousViewController = dataSource?.pageViewController(self, viewControllerBefore: currentViewController) else { return }
        setViewControllers([previousViewController], direction: .reverse, animated: animated, completion: nil)
        pageControl.currentPage += -1
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.pages.firstIndex(of: viewController) {
            if viewControllerIndex > 0 {
                return self.pages[viewControllerIndex - 1]
            }
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.pages.firstIndex(of: viewController) {
            if viewControllerIndex < self.pages.count - 1 {
                return self.pages[viewControllerIndex + 1]
            }
        }
        return nil
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let viewControllers = pageViewController.viewControllers {
            if let viewControllerIndex = self.pages.firstIndex(of: viewControllers[0]) {
                self.pageControl.currentPage = viewControllerIndex
                nextButton.setTitle(getButtonTitle(index: pageControl.currentPage), for: .normal)
            }
        }
    }
}
