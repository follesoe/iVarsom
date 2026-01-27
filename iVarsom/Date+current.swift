import Foundation

extension Date {
    /**
     Return current date.
     Please use `Date.current` instead of `Date()`,
     the latter is prohibited by lint rules/commit hook.
     */
    static var current: Date {
        return Date.now()
    }
}
