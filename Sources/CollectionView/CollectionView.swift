import SwiftUI

public struct CollectionSection<Section: Hashable, Item: Hashable>: Hashable {
    let section: Section
    let items: [Item]
    
    public init(section: Section, items: [Item]) {
        self.section = section
        self.items = items
    }
}

public struct CollectionView<Section: Hashable, Item: Hashable, Cell: View>: UIViewRepresentable {
    
    private let rows: [CollectionSection<Section, Item>]
    private let animateChanges: Bool
    private let sectionLayout: (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection
    private let cell: (IndexPath, Item) -> Cell
    
    private init(rows: [CollectionSection<Section, Item>],
                 animateChanges: Bool,
                 sectionLayout: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection,
                 @ViewBuilder cell: @escaping (IndexPath, Item) -> Cell) {
        self.rows = rows
        self.animateChanges = animateChanges
        self.sectionLayout = sectionLayout
        self.cell = cell
    }
    
    public func makeUIView(context: Context) -> UICollectionView {
        let cellIdentifier = "collectionViewCell"
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout(context: context))
        collectionView.delegate = context.coordinator
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: cellIdentifier)
        
        let dataSource = Coordinator.DataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let collectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? CollectionViewCell
            collectionViewCell?.configure(with: cell(indexPath, item))
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
        return Coordinator()
    }
    
    private func layout(context: Context) -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            return context.coordinator.sectionLayout!(sectionIndex, layoutEnvironment)
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
        
        let rowsHash = rows.hashValue
        if coordinator.rowsHash != rowsHash {
            dataSource.apply(snapshot(), animatingDifferences: animated) {
                collectionView.setNeedsFocusUpdate()
                collectionView.updateFocusIfNeeded()
            }
            coordinator.rowsHash = rowsHash
        }
    }
    
    // MARK: internal objects
    
    private class CollectionViewCell: UICollectionViewCell {
        private var hostingController: UIHostingController<Cell>?
        
        override func prepareForReuse() {
            if let hostingView = hostingController?.view {
                hostingView.removeFromSuperview()
            }
            hostingController = nil
        }
        
        func configure(with cell: Cell) {
            hostingController = UIHostingController(rootView: cell, ignoreSafeArea: true)
            if let hostView = hostingController?.view {
                hostView.frame = contentView.bounds
                hostView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                contentView.addSubview(hostView)
            }
        }
    }
    
    public class Coordinator: NSObject, UICollectionViewDelegate {
        fileprivate typealias DataSource = UICollectionViewDiffableDataSource<Section, Item>
        
        fileprivate var dataSource: DataSource? = nil
        var sectionLayout: ((Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection)?
        var rowsHash: Int? = nil
        
        public func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
            return false
        }
    }
}

// MARK: init

extension CollectionView {
    
    public init(rows: [CollectionSection<Section, Item>],
                @ViewBuilder cell: @escaping (IndexPath, Item) -> Cell) {
        self.rows = rows
        self.animateChanges = false
        self.sectionLayout = { _, layoutEnvironment in .grid(layoutEnvironment: layoutEnvironment) }
        self.cell = cell
    }
    
    public init(section: CollectionSection<Section, Item>,
                @ViewBuilder cell: @escaping (IndexPath, Item) -> Cell) {
        self.rows = [section]
        self.animateChanges = false
        self.sectionLayout = { _, layoutEnvironment in .grid(layoutEnvironment: layoutEnvironment) }
        self.cell = cell
    }
}

// MARK: functions

extension CollectionView {
    public func layout(_ sectionLayout: @escaping (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection) -> Self {
        CollectionView(rows: rows,
                       animateChanges: animateChanges,
                       sectionLayout: sectionLayout,
                       cell: cell)
    }
    
    public func animateChanges(_ animateChanges: Bool = true) -> Self {
        CollectionView(rows: rows,
                       animateChanges: animateChanges,
                       sectionLayout: sectionLayout,
                       cell: cell)
    }
}
