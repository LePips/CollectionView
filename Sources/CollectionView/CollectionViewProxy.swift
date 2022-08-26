import Foundation
import SwiftUI

public struct CollectionViewProxy {

    var collectionView: UICollectionView

    public func scrollTo(
        _ indexPath: IndexPath,
        at scrollPosition: UICollectionView.ScrollPosition = .top,
        animated: Bool = true
    ) {
        collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    }

    public func scrollTo(_ edge: Edge, animated: Bool = true) {
        switch edge {
        case .top:
            let xOffset = collectionView.contentOffset.x
            let yOffset = collectionView.adjustedContentInset.top
            collectionView.setContentOffset(.init(x: xOffset, y: -yOffset), animated: animated)
        case .bottom:
            let xOffset = collectionView.contentOffset.x
            let bottomInset = collectionView.adjustedContentInset.bottom
            let yOffset = collectionView.contentSize.height - collectionView.frame.height + bottomInset
            collectionView.setContentOffset(.init(x: xOffset, y: yOffset), animated: animated)
        case .leading:
            let xOffset = collectionView.adjustedContentInset.left
            let yOffset = collectionView.contentOffset.y
            collectionView.setContentOffset(.init(x: xOffset, y: yOffset), animated: animated)
        case .trailing:
            let rightInset = collectionView.adjustedContentInset.right
            let xOffset = collectionView.contentSize.width - collectionView.frame.width + rightInset
            let yOffset = collectionView.contentOffset.y
            collectionView.setContentOffset(.init(x: xOffset, y: yOffset), animated: animated)
        }
    }
}
