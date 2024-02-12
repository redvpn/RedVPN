// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit
import AcknowList

class AcknowledgementsViewController: UIViewController {
    var acknowledgements: [Acknow]?

    let footerText: UILabel = {
        let footerText = UILabel()
        footerText.numberOfLines = 0
        footerText.text = tr("openSourceLibrariesFooter")
        footerText.font = UIFont(name: "NunitoSans-Regular", size: 15.0)
        footerText.textColor = UIColor.white
        footerText.textAlignment = .center
        return footerText
    }()

    let tableView: UITableView = {
       let tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.white
        tableView.register(UITableViewCell.self)
        tableView.isScrollEnabled = true
        tableView.alwaysBounceVertical = false
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .backgroundDark
        tableView.semanticContentAttribute = .forceLeftToRight
        return tableView
    }()

    init() {
        super.init(nibName: nil, bundle: nil)

        guard let path = Bundle.main.path(forResource: "acknowledgements", ofType: "plist") else { return }

        var acknowledgements: [Acknow] = []
        let parser = AcknowParser(plistPath: path)
        acknowledgements.append(contentsOf: parser.parseAcknowledgements())

        let sortedAcknowledgements = acknowledgements.sorted {(ack1: Acknow, ack2: Acknow) -> Bool in
            let result = ack1.title.compare(
                ack2.title,
                options: [],
                range: nil,
                locale: Locale.current)
            return (result == ComparisonResult.orderedAscending)
        }
        self.acknowledgements = sortedAcknowledgements
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupFooterView()

        restorationIdentifier = "AcknowledgementsVC"
    }

    func setupFooterView() {
        guard let footerView = tableView.tableFooterView else { return }

        footerView.addSubview(footerText)
        footerText.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footerText.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            footerText.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 30.0)
        ])
    }
}

extension AcknowledgementsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return acknowledgements?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath)

        let emptyView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: CGFloat.leastNormalMagnitude))

        if let acknowledgements = self.acknowledgements {
            let acknowledgement = acknowledgements[indexPath.row]

            tableView.tableHeaderView = emptyView
            cell.textLabel?.text = acknowledgement.title
            cell.textLabel?.textColor = UIColor.white
            cell.textLabel?.font = UIFont(name: "SFProDisplay-Regular", size: 18.0)

            cell.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
            cell.layoutMargins = UIEdgeInsets.zero
            cell.selectionStyle = .none
            cell.tintColor = .white
            cell.backgroundColor = .backgroundDark
            cell.preservesSuperviewLayoutMargins = false
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }

}

extension AcknowledgementsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let acknowledgements = self.acknowledgements,
            let acknowledgement = acknowledgements[(indexPath as NSIndexPath).row] as Acknow?,
            let navigationController = self.navigationController {
            let viewController = AcknowledgementViewController(acknowledgement: acknowledgement)
            let backItem = UIBarButtonItem(title: acknowledgement.title, style: .plain, target: nil, action: nil)
            navigationItem.backBarButtonItem = backItem
            navigationController.pushViewController(viewController, animated: false)
        }
    }
}
