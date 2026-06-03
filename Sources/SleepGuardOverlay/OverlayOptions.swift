import Foundation

struct OverlayOptions {
    var configURL: URL?
    var preview = false
    var noLogout = false

    init(arguments: [String]) {
        var iterator = arguments.dropFirst().makeIterator()
        while let argument = iterator.next() {
            switch argument {
            case "--config":
                if let path = iterator.next() {
                    configURL = URL(fileURLWithPath: path)
                }
            case "--preview":
                preview = true
            case "--no-logout":
                noLogout = true
            default:
                break
            }
        }
    }
}
