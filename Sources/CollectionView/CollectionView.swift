import SwiftUI

public struct CollectionView<Section: Hashable, Item: Hashable, Cell: View>: UIViewRepresentable {

    private var rows: [CollectionSection<Section, Item>]
    private var animateChanges: Bool
    private var onEdgeReached: (Edge) -> Void
    private var willReachEdge: (Edge) -> Void
    private var willReachEdgeInsets: EdgeInsets
    private var configuration: (CollectionViewConfiguration) -> Void
    private var sectionLayout: (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection
    private var cell: (IndexPath, Item, CollectionViewProxy) -> Cell

    private init(
        rows: [CollectionSection<Section, Item>],
        animateChanges: Bool,
        onEdgeReached: @escaping (Edge) -> Void,
        willReachEdge: @escaping (Edge) -> Void,
        willReachEdgeInsets: EdgeInsets,
        configuration: @escaping (CollectionViewConfiguration) -> Void,
        sectionLayout: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection,
        @ViewBuilder cell: @escaping (IndexPath, Item, CollectionViewProxy) -> Cell
    ) {
        self.rows = rows
        self.animateChanges = animateChanges
        self.onEdgeReached = onEdgeReached
        self.willReachEdge = willReachEdge
        self.willReachEdgeInsets = willReachEdgeInsets
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

    // MARK: Coordinator

    public class Coordinator: NSObject, UICollectionViewDelegate {
        typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>

        var dataSource: DataSource?
        var sectionLayout: ((Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)?
        var rowsHash: Int?
        var parent: CollectionView!

        private var onEdgeReachedStore: Set<Edge> = []
        private var willReachEdgeStore: Set<Edge> = []

        public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
            false
        }

        public func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let scrollableHorizontally = scrollView.contentSizePlusInsets.width > scrollView.frame.size.width
            let scrollableVertically = scrollView.contentSizePlusInsets.height > scrollView.frame.size.height

            for edge in Edge.allCases {
                var hasReachedEdge: Bool = false
                var willReachEdge: Bool = false

                switch edge {
                case .top:
                    hasReachedEdge = scrollableVertically && scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top
                    willReachEdge = scrollableVertically && scrollView.contentOffset.y <= -scrollView.adjustedContentInset.top + parent
                        .willReachEdgeInsets.top
                case .bottom:
                    hasReachedEdge = scrollableVertically && scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame
                        .height + scrollView.adjustedContentInset.bottom
                    willReachEdge = scrollableVertically && scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame
                        .height + scrollView.adjustedContentInset.bottom - parent.willReachEdgeInsets.bottom
                case .leading:
                    hasReachedEdge = scrollableHorizontally && scrollView.contentOffset.x <= -scrollView.adjustedContentInset.left
                    willReachEdge = scrollableHorizontally && scrollView.contentOffset.x <= -scrollView.adjustedContentInset.left + parent
                        .willReachEdgeInsets.leading
                case .trailing:
                    hasReachedEdge = scrollableHorizontally && scrollView.contentOffset.x >= scrollView.contentSize.width - scrollView.frame
                        .width + scrollView.adjustedContentInset.right
                    willReachEdge = scrollableHorizontally && scrollView.contentOffset.x >= scrollView.contentSize.width - scrollView.frame
                        .width + scrollView.adjustedContentInset.right - parent.willReachEdgeInsets.trailing
                }

                if hasReachedEdge {
                    if !onEdgeReachedStore.contains(edge) {
                        onEdgeReachedStore.insert(edge)
                        parent.onEdgeReached(edge)
                    }
                } else {
                    onEdgeReachedStore.remove(edge)
                }

                if willReachEdge {
                    if !willReachEdgeStore.contains(edge) {
                        willReachEdgeStore.insert(edge)
                        parent.willReachEdge(edge)
                    }
                } else {
                    willReachEdgeStore.remove(edge)
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
            onEdgeReached: { _ in },
            willReachEdge: { _ in },
            willReachEdgeInsets: .zero,
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

    func onEdgeReached(_ onEdgeReached: @escaping (Edge) -> Void) -> Self {
        var copy = self
        copy.onEdgeReached = onEdgeReached
        return copy
    }

    func willReachEdge(insets: EdgeInsets = .zero, _ willReachEdge: @escaping (Edge) -> Void) -> Self {
        var copy = self
        copy.willReachEdgeInsets = insets
        copy.willReachEdge = willReachEdge
        return copy
    }

    func configuration(_ configuration: @escaping (CollectionViewConfiguration) -> Void) -> Self {
        var copy = self
        copy.configuration = configuration
        return copy
    }
}
