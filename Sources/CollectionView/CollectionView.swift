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

public struct CollectionView<Section: Hashable, Item: Hashable, Cell: View>: UIViewRepresentable {

    private var rows: [CollectionSection<Section, Item>]
    private var animateChanges: Bool
    private var onBoundaryReached: (Boundary) -> Void
    private var willReachBoundary: (Boundary) -> Void
    private var willReachBoundaryOffset: CGFloat?
    private var configuration: (CollectionViewConfiguration) -> Void
    private var sectionLayout: (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection
    private var cell: (IndexPath, Item, CollectionViewProxy) -> Cell

    private init(
        rows: [CollectionSection<Section, Item>],
        animateChanges: Bool,
        onBoundaryReached: @escaping (Boundary) -> Void,
        willReachBoundary: @escaping (Boundary) -> Void,
        willReachBoundaryOffset: CGFloat?,
        configuration: @escaping (CollectionViewConfiguration) -> Void,
        sectionLayout: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection,
        @ViewBuilder cell: @escaping (IndexPath, Item, CollectionViewProxy) -> Cell
    ) {
        self.rows = rows
        self.animateChanges = animateChanges
        self.onBoundaryReached = onBoundaryReached
        self.willReachBoundary = willReachBoundary
        self.willReachBoundaryOffset = willReachBoundaryOffset
        self.configuration = configuration
        self.sectionLayout = sectionLayout
        self.cell = cell
    }

    public func makeUIView(context: Context) -> UICollectionView {
        let cellIdentifier = "collectionViewCell"

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout(context: context))
        collectionView.delegate = context.coordinator
        collectionView.register(CollectionViewCell<Cell>.self, forCellWithReuseIdentifier: cellIdentifier)
        collectionView.backgroundColor = nil
        
        let configuration = CollectionViewConfiguration(collectionView: collectionView)
        self.configuration(configuration)
        configuration.setCollectionView()
        
        let proxy = CollectionViewProxy(collectionView: collectionView)
        let dataSource = Coordinator.DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let collectionViewCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: cellIdentifier,
                for: indexPath
            ) as? CollectionViewCell<Cell>
            collectionViewCell?.configure(with: cell(indexPath, item, proxy))
            return collectionViewCell
        }
        context.coordinator.dataSource = dataSource

        reloadData(in: collectionView, context: context)
        
        return collectionView
    }

    public func updateUIView(_ uiView: UICollectionView, context: Context) {
        reloadData(in: uiView, context: context, animated: animateChanges)
    }

    public func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator()
        coordinator.parent = self
        return coordinator
    }

    private func layout(context: Context) -> UICollectionViewLayout {
        // TODO: configuration for alternate directions
        UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            context.coordinator.sectionLayout!(sectionIndex, layoutEnvironment)
        }
    }

    private func snapshot() -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        for row in rows {
            snapshot.appendSections([row.section])
            snapshot.appendItems(row.items, toSection: row.section)
        }
        return snapshot
    }

    private func reloadData(in collectionView: UICollectionView, context: Context, animated: Bool = false) {
        let coordinator = context.coordinator
        coordinator.sectionLayout = self.sectionLayout

        guard let dataSource = coordinator.dataSource else { return }

        if coordinator.rowsHash != rows.hashValue {
            dataSource.apply(snapshot(), animatingDifferences: animated) {
                collectionView.setNeedsFocusUpdate()
                collectionView.updateFocusIfNeeded()
            }
            coordinator.rowsHash = rows.hashValue
        }
    }

    // MARK: internal objects

    public class Coordinator: NSObject, UICollectionViewDelegate {
        fileprivate typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>

        fileprivate var dataSource: DataSource?
        var sectionLayout: ((Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)?
        var rowsHash: Int?
        var parent: CollectionView?

        private var onBoundaryReachedStore: Set<Boundary> = []
        private var willReachBoundaryStore: Set<Boundary> = []
        private var lastScrollViewOffsetBoundary: CGFloat = 0

        public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
            false
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let scrollableHorizontally = scrollView.contentSizePlusInsets.width > scrollView.frame.size.width
            let scrollableVertically = scrollView.contentSizePlusInsets.height > scrollView.frame.size.height

            // TODO: different hasReachedBoundary implementation
            // TODO: implement willReachBoundary

            for boundary in Boundary.allCases {
                let hasReachedBoundary: Bool = {
                    switch boundary {
                    case .top:
                        return scrollableVertically && scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top
                    case .bottom:
                        let bottomInset = scrollView.adjustedContentInset.bottom
                        let xOffset = scrollView.contentSize.height - scrollView.frame.height + bottomInset
                        
                        return scrollableVertically && scrollView.contentOffset.y >= xOffset
                    case .left:
                        return scrollableHorizontally && scrollView.contentOffset.x <= -scrollView.adjustedContentInset.left
                    case .right:
                        let rightInset = scrollView.adjustedContentInset.right
                        let xOffset = scrollView.contentSize.width - scrollView.frame.width + rightInset
                        
                        return scrollableHorizontally && scrollView.contentOffset.x >= xOffset
                    }
                }()

                if hasReachedBoundary {
                    if !onBoundaryReachedStore.contains(boundary) {
                        onBoundaryReachedStore.insert(boundary)
                        parent?.onBoundaryReached(boundary)
                    }
                } else {
                    onBoundaryReachedStore.remove(boundary)
                }
            }
        }
    }
}

// MARK: init

public extension CollectionView {
    init(
        rows: [CollectionSection<Section, Item>],
        @ViewBuilder cell: @escaping (IndexPath, Item, CollectionViewProxy) -> Cell
    ) {
        self.init(
            rows: rows,
            animateChanges: false,
            onBoundaryReached: { _ in },
            willReachBoundary: { _ in },
            willReachBoundaryOffset: nil,
            configuration: { _ in },
            sectionLayout: { _, layoutEnvironment in .grid(layoutEnvironment: layoutEnvironment) },
            cell: cell
        )
    }
}

public extension CollectionView where Section == Int {
    init(
        items: [Item],
        @ViewBuilder cell: @escaping (IndexPath, Item, CollectionViewProxy) -> Cell
    ) {
        self.init(rows: [.init(section: 0, items: items)], cell: cell)
    }
}

// MARK: functions

public extension CollectionView {
    func layout(_ sectionLayout: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection) -> Self {
        var copy = self
        copy.sectionLayout = sectionLayout
        return copy
    }

    func animateChanges(_ animateChanges: Bool = true) -> Self {
        var copy = self
        copy.animateChanges = animateChanges
        return copy
    }

    func onBoundaryReached(_ onBoundaryReached: @escaping (Boundary) -> Void) -> Self {
        var copy = self
        copy.onBoundaryReached = onBoundaryReached
        return copy
    }

    // TODO: implement willReachBoundary
//    func willReachBoundary(offset: CGFloat = 50, _ willReachBoundary: @escaping (Boundary) -> Void) -> Self {
//        var copy = self
//        copy.willReachBoundaryOffset = offset
//        copy.willReachBoundary = willReachBoundary
//        return copy
//    }
    
    func configuration(_ configuration: @escaping (CollectionViewConfiguration) -> Void) -> Self {
        var copy = self
        copy.configuration = configuration
        return copy
    }
}
