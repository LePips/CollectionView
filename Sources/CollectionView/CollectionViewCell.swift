import Foundation
import SwiftUI

public struct SelfSizingConfig {

    var selfSizeHorizontally: Bool?
    var selfSizeVertically: Bool?
    var canExceedCollectionWidth: Bool
    var canExceedCollectionHeight: Bool

    public init(
        selfSizeHorizontally: Bool? = nil,
        selfSizeVertically: Bool? = nil,
        canExceedCollectionWidth: Bool = true,
        canExceedCollectionHeight: Bool = true
    ) {
        self.selfSizeHorizontally = selfSizeHorizontally
        self.selfSizeVertically = selfSizeVertically
        self.canExceedCollectionWidth = canExceedCollectionWidth
        self.canExceedCollectionHeight = canExceedCollectionHeight
    }
}

class CollectionViewCell<Cell: View>: UICollectionViewCell {

    var selfSizingConfig: SelfSizingConfig = .init(selfSizeHorizontally: true, selfSizeVertically: true)
    private var hostingController: CollectionViewCellHostingController<Cell>?

    override func prepareForReuse() {
        if let hostingView = hostingController?.view {
            hostingView.removeFromSuperview()
        }
        hostingController = nil
    }

    func configure(with cell: Cell) {
        hostingController = CollectionViewCellHostingController(rootView: cell)
        if let hostView = hostingController?.view {
            hostView.frame = contentView.bounds
            hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            hostView.backgroundColor = nil
            contentView.addSubview(hostView)
        }
    }

    override func systemLayoutSizeFitting(
        _ targetSize: CGSize,
        withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,

        verticalFittingPriority: UILayoutPriority
    ) -> CGSize {

        let selfSizeHorizontal = selfSizingConfig.selfSizeHorizontally ?? (horizontalFittingPriority != .required)
        let selfSizeVertical = selfSizingConfig.selfSizeVertically ?? (verticalFittingPriority != .required)

        guard selfSizeVertical || selfSizeHorizontal else { return targetSize }

        hostingController?.view.setNeedsLayout()
        hostingController?.view.layoutIfNeeded()

        let size = hostingController?.sizeThatFits(
            in: targetSize,
            maxSize: maxSizeForSelfSizing,
            selfSizeHorizontal: selfSizeHorizontal,
            selfSizeVertical: selfSizeVertical
        )
        return size ?? .zero
    }

    var maxSizeForSelfSizing: OptionalSize {
        OptionalSize(
            width: selfSizingConfig.canExceedCollectionWidth ? nil : .infinity,
            height: selfSizingConfig.canExceedCollectionHeight ? nil : .infinity
        )
    }
}

private class CollectionViewCellHostingController<Content: View>: UIHostingController<Content> {

    override init(rootView: Content) {
        super.init(rootView: rootView)
        disableSafeArea()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func sizeThatFits(in size: CGSize, maxSize: OptionalSize, selfSizeHorizontal: Bool, selfSizeVertical: Bool) -> CGSize {
        guard selfSizeHorizontal || selfSizeVertical else { return max(size, maxSize) }

        view.layoutIfNeeded()

        let fittingSize = CGSize(
            width: selfSizeHorizontal ? maxSize.width ?? .greatestFiniteMagnitude : min(size.width, maxSize.width),
            height: selfSizeVertical ? maxSize.height ?? .greatestFiniteMagnitude : min(size.height, maxSize.height)
        )

        // Find the desired size
        var desiredSize = self.sizeThatFits(in: fittingSize)

        // Accounting for 'greedy' swiftUI views that take up as much space as they can
        switch (desiredSize.width, desiredSize.height) {
        case (.greatestFiniteMagnitude, .greatestFiniteMagnitude):
            desiredSize = self.sizeThatFits(in: max(size, maxSize))
        case (.greatestFiniteMagnitude, _):
            desiredSize = self.sizeThatFits(in: CGSize(
                width: min(size.width, maxSize.width),
                height: fittingSize.height
            ))
        case (_, .greatestFiniteMagnitude):
            desiredSize = self.sizeThatFits(in: CGSize(
                width: fittingSize.width,
                height: min(size.height, maxSize.height)
            ))
        default:
            break
        }

        // Ensure correct dimensions in non-self sizing axes
        if !selfSizeHorizontal { desiredSize.width = size.width }
        if !selfSizeVertical { desiredSize.height = size.height }

        return max(desiredSize, maxSize)
    }
}
