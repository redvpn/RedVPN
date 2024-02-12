// SPDX-License-Identifier: MIT
// Copyright © 2018-2019 WireGuard LLC. All Rights Reserved.

import UIKit
import Connectivity
import SwiftMessages

class TunnelListCell: UITableViewCell, NetworkStatusListener {

    private var statusObservationToken: AnyObject?
    private var checkingConnectivityObservationToken: AnyObject?
    private var gettingNewEndpointsObservationToken: AnyObject?

    var tunnel: TunnelContainer? {
        didSet(value) {
            // Bind to the tunnel's status
            update(from: tunnel?.redVpnStatus)
            statusObservationToken = tunnel?.observe(\.status) { [weak self] tunnel, _ in
                self?.update(from: tunnel.redVpnStatus)
            }
            checkingConnectivityObservationToken = tunnel?.observe(\.isCheckingConnectivity) { [weak self] tunnel, _ in
                self?.update(from: tunnel.redVpnStatus)
            }
            gettingNewEndpointsObservationToken = tunnel?.observe(\.isGettingNewEndpoints) { [weak self] tunnel, _ in
                self?.update(from: tunnel.redVpnStatus)
            }
        }
    }
    var onImageTapped: (() -> Void)?

    let redVpnImageView: UIImageView = {
        let redVpnImageView = UIImageView()
        redVpnImageView.image = UIImage(named: "redVpnInactive")
        redVpnImageView.isUserInteractionEnabled = true
        redVpnImageView.contentMode = .center
        redVpnImageView.translatesAutoresizingMaskIntoConstraints = false
        return redVpnImageView
    }()

    let stateLabel: UILabel = {
        let stateLabel = UILabel()
        stateLabel.font = UIFont(name: "SFProDisplay-Regular", size: 20.0)
        stateLabel.numberOfLines = 0
        stateLabel.textColor = .white
        stateLabel.text = tr("vpnStateOff")
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        return stateLabel
    }()

    let infoLabel: UILabel = {
        let infoLabel = UILabel()
        infoLabel.font = UIFont(name: "SFProText-Regular", size: 18.0)
        infoLabel.numberOfLines = 0
        infoLabel.textColor = .white
        infoLabel.text = tr("tapToConnect")
        infoLabel.textAlignment = NSTextAlignment.center
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        return infoLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .backgroundDark

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        tapGestureRecognizer.numberOfTapsRequired = 1
        redVpnImageView.addGestureRecognizer(tapGestureRecognizer)

        setupViews()
    }

    func pulseAnimation(view: UIView) {
        guard view.layer.animation(forKey: "pulse") == nil else {
            return
        }

        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 0.5
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        pulseAnimation.autoreverses = true

        let alphaAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        alphaAnimation.duration = 0.5
        alphaAnimation.fromValue = 1.0
        alphaAnimation.toValue = 0.7
        alphaAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        alphaAnimation.autoreverses = true

        let delayAnimation = CABasicAnimation(keyPath: "delay")
        delayAnimation.duration = 0.75
        delayAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        delayAnimation.autoreverses = true

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [pulseAnimation, alphaAnimation, delayAnimation]
        animationGroup.duration = 1.25
        animationGroup.repeatCount = .infinity
        animationGroup.fillMode = .forwards
        animationGroup.isRemovedOnCompletion = false

        view.layer.add(animationGroup, forKey: "pulse")
    }

    func stopAnimation() {
        redVpnImageView.layer.removeAllAnimations()
    }

    private func setupViews() {

        contentView.addSubview(redVpnImageView)
        contentView.addSubview(stateLabel)
        contentView.addSubview(infoLabel)

        NSLayoutConstraint.activate([
            redVpnImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            redVpnImageView.topAnchor.constraint(equalTo: contentView.safeTopAnchor, constant: 40),
            redVpnImageView.widthAnchor.constraint(equalToConstant: 295.0),
            redVpnImageView.heightAnchor.constraint(equalToConstant: 295.0),

            stateLabel.topAnchor.constraint(equalTo: redVpnImageView.bottomAnchor, constant: 28),
            stateLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            infoLabel.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 16),
            infoLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            infoLabel.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 20),
            infoLabel.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -20)
        ])
    }

    @objc func imageTapped() {
        onImageTapped?()
    }

    private func update(from status: TunnelStatus?) {
        guard let status = status else {
            reset()
            return
        }
        DispatchQueue.main.async { [weak redVpnImageView, weak stateLabel, weak infoLabel] in
            guard let redVpnImageView = redVpnImageView, let stateLabel = stateLabel, let infoLabel = infoLabel else { return }
            if status == .active && ConnectivityManager.shared.isNetworkAvailable {
                redVpnImageView.image = UIImage(named: "redVpnActive")
                let text = tr("vpnStateOn")
                let textToColor = tr("on")
                let range = (text as NSString).range(of: textToColor)
                let attributedText = NSMutableAttributedString(string: text)
                attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red2, range: range)
                stateLabel.attributedText = attributedText
                infoLabel.text = tr("tapToDisconnect")
            } else {
                redVpnImageView.image = UIImage(named: "redVpnInactive")
                let text = status == .activating ? tr("vpnStateConnecting") : tr("vpnStateOff")
                let textToColor = status == .activating ? tr("connecting") : tr("off")
                let range = (text as NSString).range(of: textToColor)
                let attributedText = NSMutableAttributedString(string: text)
                attributedText.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.light, range: range)
                stateLabel.attributedText = attributedText
                infoLabel.text = status == .activating ? tr("pleaseWait") : tr("tapToConnect")
            }
            redVpnImageView.isUserInteractionEnabled = (status == .inactive || status == .active) && ConnectivityManager.shared.isNetworkAvailable
            if status == .activating || status == .deactivating {
                self.pulseAnimation(view: redVpnImageView)
            } else {
                self.stopAnimation()
            }
        }
    }

    func networkStatusDidChange(status: ConnectivityStatus) {
        if ConnectivityManager.shared.isNetworkAvailable == false {
            update(from: TunnelStatus.inactive)
            if SwiftMessages.current(id: SwiftMessages.noInternetConnetionMessageId) == nil {
                SwiftMessages.hideAll()
            }
            SwiftMessages.show(type: MessageType.error, message: tr("noInternetConnection"), duration: MessageDuration.indefinite, id: SwiftMessages.noInternetConnetionMessageId)
        } else {
            update(from: tunnel?.redVpnStatus)
            SwiftMessages.hide(id: SwiftMessages.noInternetConnetionMessageId)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func reset() {
        redVpnImageView.image = UIImage(named: "redVpnInactive")
        redVpnImageView.isUserInteractionEnabled = false
        stopAnimation()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reset()
    }
}
