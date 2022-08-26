import SwiftUI

public class CollectionViewConfiguration {

    var collectionView: UICollectionView

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }

    public var showsVerticalScrollIndicator: Bool = true
    public var showsHorizontalScrollIndicator: Bool = true
    public var keyboardDismissMode: UIScrollView.KeyboardDismissMode = .none

    func setCollectionView() {
        collectionView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
        collectionView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        collectionView.keyboardDismissMode = keyboardDismissMode
    }
}
