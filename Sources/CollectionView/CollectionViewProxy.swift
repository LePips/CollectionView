import Foundation
import UIKit

public struct CollectionViewProxy {
    
    var collectionView: UICollectionView
    
    public func scrollTo(_ indexPath: IndexPath,
                         at scrollPosition: UICollectionView.ScrollPosition = .top,
                         animated: Bool = true) {
        collectionView.scrollToItem(at: indexPath, at: scrollPosition, animated: animated)
    }
    
    /// Scrolls to the given boundary
    public func scrollTo(_ boundary: Boundary, animated: Bool = true) {
        switch boundary {
        case .top:
            let xOffset = collectionView.contentOffset.x
            let yOffset = collectionView.adjustedContentInset.top
            collectionView.setContentOffset(.init(x: xOffset, y: -yOffset), animated: animated)
        case .bottom:
            let xOffset = collectionView.contentOffset.x
            let bottomInset = collectionView.adjustedContentInset.bottom
            let yOffset = collectionView.contentSize.height - collectionView.frame.height + bottomInset
            collectionView.setContentOffset(.init(x: xOffset, y: yOffset), animated: animated)
        case .left:
            let xOffset = collectionView.adjustedContentInset.left
            let yOffset = collectionView.contentOffset.y
            collectionView.setContentOffset(.init(x: xOffset, y: yOffset), animated: animated)
        case .right:
            let rightInset = collectionView.adjustedContentInset.right
            let xOffset = collectionView.contentSize.width - collectionView.frame.width + rightInset
            let yOffset = collectionView.contentOffset.y ?? 0
            collectionView.setContentOffset(.init(x: xOffset, y: yOffset), animated: animated)
        }
    }
}
