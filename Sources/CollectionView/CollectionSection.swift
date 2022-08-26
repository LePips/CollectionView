import Foundation

public struct CollectionSection<Section: Hashable, Item: Hashable>: Hashable {
    let section: Section
    let items: [Item]

    public init(section: Section, items: [Item]) {
        self.section = section
        self.items = items
    }
}
