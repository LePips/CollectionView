import Foundation
import SwiftUI

struct OptionalSize {

    static let none = OptionalSize()

    let width: CGFloat?
    let height: CGFloat?

    init(width: CGFloat? = nil, height: CGFloat? = nil) {
        self.width = width
        self.height = height
    }

    init(_ size: CGSize) {
        width = size.width
        height = size.height
    }
}

// MARK: min/max

func min(_ size: CGSize, _ optionalSize: OptionalSize) -> CGSize {
    CGSize(
        width: min(size.width, optionalSize.width ?? size.width),
        height: min(size.height, optionalSize.height ?? size.height)
    )
}

func max(_ size: CGSize, _ optionalSize: OptionalSize) -> CGSize {
    CGSize(
        width: max(size.width, optionalSize.width ?? size.width),
        height: max(size.height, optionalSize.height ?? size.height)
    )
}

func min(_ x: CGFloat, _ y: CGFloat?) -> CGFloat {
    min(x, y ?? x)
}

func max(_ x: CGFloat, _ y: CGFloat?) -> CGFloat {
    max(x, y ?? x)
}

// MARK: Extensions

extension UIScrollView {
    var contentSizePlusInsets: CGSize {
        CGSize(
            width: contentSize.width + adjustedContentInset.left + adjustedContentInset.right,
            height: contentSize.height + adjustedContentInset.bottom + adjustedContentInset.top
        )
    }
}

public extension EdgeInsets {
    static let zero: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
}

extension View {
    func copy<Value>(modifying keyPath: WritableKeyPath<Self, Value>, with newValue: Value) -> Self {
        var copy = self
        copy[keyPath: keyPath] = newValue
        return copy
    }
}
