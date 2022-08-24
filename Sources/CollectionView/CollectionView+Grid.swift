import Foundation
import UIKit

// MARK: Grid

extension NSCollectionLayoutSection {
    
    public enum GridLayoutMode {
        case fixedNumberOfColumns(Int)
        case adaptive(withMinItemSize: CGFloat)
    }
    
    static public func grid(
        layoutEnvironment: NSCollectionLayoutEnvironment,
        layoutMode: GridLayoutMode = .fixedNumberOfColumns(2),
        itemSpacing: CGFloat = 5,
        lineSpacing: CGFloat = 5,
        itemSize: NSCollectionLayoutDimension = .estimated(150),
        sectionInsets: NSDirectionalEdgeInsets = .init(top: 0, leading: 20, bottom: 0, trailing: 20)
    ) -> NSCollectionLayoutSection {
        let count: Int = {
            switch layoutMode
            {
            case let .fixedNumberOfColumns(count):
                return count
            case let .adaptive(minItemSize):
                let containerSize = layoutEnvironment.container.effectiveContentSize.width
                return max(1, Int(containerSize / minItemSize))
            }
        }()

        let itemLayoutSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: itemSize)
        let item = NSCollectionLayoutItem(layoutSize: itemLayoutSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: count)
        
        group.interItemSpacing = .fixed(itemSpacing)

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = lineSpacing
        section.contentInsets = sectionInsets
        // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells
        section.visibleItemsInvalidationHandler = { _, _, _ in }
        
        return section
    }
    
    public static func orthogonalGrid(
        gridSize: Int = 2,
        itemDimension: NSCollectionLayoutDimension = .fractionalWidth(0.9),
        sectionDimension: NSCollectionLayoutDimension = .fractionalHeight(0.8),
        scrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .continuous,
        gridSpacing: CGFloat = 5,
        itemInsets: NSDirectionalEdgeInsets = .zero,
        sectionInsets: NSDirectionalEdgeInsets = .zero
    ) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let groupSize = NSCollectionLayoutSize(widthDimension: itemDimension, heightDimension: sectionDimension)
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: gridSize)
        
        group.interItemSpacing = .fixed(gridSpacing)
        group.contentInsets = itemInsets

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = scrollingBehavior
        section.contentInsets = sectionInsets
        // If this isn't defined, there is a bug in UICVCompositional Layout that will fail to update sizes of cells
        section.visibleItemsInvalidationHandler = { _, _, _ in }
        
        return section
    }
}
