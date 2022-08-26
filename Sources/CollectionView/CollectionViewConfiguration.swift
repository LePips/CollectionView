import SwiftUI

public class CollectionViewConfiguration {

    // UICollectionView configuration
    public var showsVerticalScrollIndicator: Bool = true
    public var showsHorizontalScrollIndicator: Bool = true
    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode = .none

    // CollectionView configuration
    public var animateChanges: Bool = true

    func configure(_ collectionView: UICollectionView) {
        collectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        collectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        collectionView.keyboardDismissMode = keyboardDismissMode
    }
}
