import SwiftUI
import UIKit

enum RemoteCommand {
    case togglePlayback
    case decreaseSpeed
    case increaseSpeed
    case moveBackward
    case moveForward
    case restart
}

@MainActor
struct RemoteCommandView: UIViewControllerRepresentable {
    let onCommand: (RemoteCommand) -> Void

    func makeUIViewController(context: Context) -> KeyCommandViewController {
        let controller = KeyCommandViewController()
        controller.onCommand = onCommand
        return controller
    }

    func updateUIViewController(_ controller: KeyCommandViewController, context: Context) {
        controller.onCommand = onCommand
        controller.becomeFirstResponderIfNeeded()
    }
}

@MainActor
final class KeyCommandViewController: UIViewController {
    var onCommand: ((RemoteCommand) -> Void)?

    override var canBecomeFirstResponder: Bool { true }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        becomeFirstResponderIfNeeded()
    }

    func becomeFirstResponderIfNeeded() {
        guard viewIfLoaded?.window != nil, !isFirstResponder else { return }
        becomeFirstResponder()
    }

    override var keyCommands: [UIKeyCommand]? {
        [
            UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handleKey(_:))),
            UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(handleKey(_:))),
            UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(handleKey(_:))),
            UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleKey(_:))),
            UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleKey(_:))),
            UIKeyCommand(input: "r", modifierFlags: [], action: #selector(handleKey(_:)))
        ]
    }

    @objc private func handleKey(_ command: UIKeyCommand) {
        switch command.input {
        case " ": onCommand?(.togglePlayback)
        case UIKeyCommand.inputUpArrow: onCommand?(.decreaseSpeed)
        case UIKeyCommand.inputDownArrow: onCommand?(.increaseSpeed)
        case UIKeyCommand.inputLeftArrow: onCommand?(.moveBackward)
        case UIKeyCommand.inputRightArrow: onCommand?(.moveForward)
        case "r": onCommand?(.restart)
        default: break
        }
    }
}
