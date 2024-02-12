// SPDX-License-Identifier: MIT
// Copyright © 2018-2023 WireGuard LLC. All Rights Reserved.

import UIKit

class NavigationMenuCell: UITableViewCell {

    private var isSelectedCell = false {
            didSet {
                setSelectedViewIndicatorColor(isSelectedCell ? .white : .clear)
            }
        }

    private let iconImageView: UIImageView = {
        let iconImageView = UIImageView()
        iconImageView.tintColor = UIColor.primaryDark
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        return iconImageView
    }()

    private let menuLabel: UILabel = {
        let menuLabel = UILabel()
        menuLabel.font = UIFont(name: "SFProDisplay-Regular", size: 20.0)
        menuLabel.textColor = UIColor.primaryDark
        menuLabel.textAlignment = .left
        menuLabel.translatesAutoresizingMaskIntoConstraints = false
        return menuLabel
    }()

    private let selectedViewIndicator: UIView = {
        let selectedViewIndicator = UIView()
        selectedViewIndicator.translatesAutoresizingMaskIntoConstraints = false
        return selectedViewIndicator
    }()

    private let contentCornerRadius: CGFloat = 16.0
    private let contentInsets = UIEdgeInsets.zero

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.layer.cornerRadius = contentCornerRadius
        self.clipsToBounds = true
        self.preservesSuperviewLayoutMargins = false
        self.layoutMargins = contentInsets
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(menuLabel)
        contentView.addSubview(selectedViewIndicator)

        NSLayoutConstraint.activate([
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24.0),
            iconImageView.widthAnchor.constraint(equalToConstant: 24.0),
            iconImageView.heightAnchor.constraint(equalToConstant: 24.0),

            menuLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            menuLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 15.0),

            selectedViewIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectedViewIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectedViewIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            selectedViewIndicator.heightAnchor.constraint(equalToConstant: 2.0)
        ])
    }

    func configureCell(menu: MenuItem) {
        menuLabel.text = menu.text
        iconImageView.image = UIImage(named: menu.icon)?.withRenderingMode(.alwaysTemplate)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
            super.setSelected(selected, animated: animated)
            setBackgroundColor(selected)
            setColors(UIColor.white)
        }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
            super.setHighlighted(highlighted, animated: animated)
            isSelectedCell = highlighted
            setColors(UIColor.white)
        }

    private func setBackgroundColor(_ selectedOrHighlighted: Bool) {
        let color: UIColor = selectedOrHighlighted ? .darkGray : .black
        if #available(iOS 14.0, *) {
            contentView.backgroundColor = color
            selectedViewIndicator.backgroundColor = isSelectedCell ? .white : .clear
        } else {
            selectedBackgroundView!.backgroundColor = color
            setSelectedViewIndicatorColor(isSelectedCell ? .white : .clear)
        }
    }

    private func setSelectedViewIndicatorColor(_ color: UIColor) {
        selectedViewIndicator.backgroundColor = color
    }

    private func setColors(_ color: UIColor) {
        menuLabel.textColor = color
        iconImageView.tintColor = color
    }
}
