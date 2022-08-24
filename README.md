# CollectionView

A basic wrapper for `UICollectionView` for overcoming `LazyVGrid/LazyHGrid` performance issues.

Initially build from the article series [SwiftUICollection](https://github.com/defagos/SwiftUICollection) and influenced by [ASCollectionView](https://github.com/apptekstudios/ASCollectionView).

# Usage

Currently, this is supposed to be a basic wrapper for displaying many items for performance improvements. Further enhancements may come.

<details>
<summary>iOS Example</summary>

```swift
struct ContentView: View {
    
    static let colors: [Color] = [.blue, .red, .green, .yellow, .purple, .cyan, .indigo, .mint, .orange]
    
    @State
    var items = (0..<4).map { "\($0)" }
    
    var body: some View {
        CollectionView(section: CollectionSection(section: 0, items: items)) { path, item in
            Button {
                items.append("\(items.count)")
            } label: {
                ZStack {
                    Self.colors.randomElement()
                    
                    Text(item)
                }
                .frame(width: 90, height: 90)
            }
        }
        .layout { _, environment in
				.grid(layoutEnvironment: environment,
					layoutMode: .fixedNumberOfColumns(4),
					itemSpacing: 0,
					lineSpacing: 0,
					itemSize: .estimated(90))
        }
        .animateChanges()
        .ignoresSafeArea(.all)
    }
}
```
</details>

<details>
<summary>tvOS Example</summary>

```swift
struct ContentView: View {
    
    static let colors: [Color] = [.blue, .red, .green, .yellow, .purple, .cyan, .indigo, .mint, .orange]
    
    @State
    var items = (0..<4).map { "\($0)" }
    
    var body: some View {
        CollectionView(section: CollectionSection(section: 0, items: items)) { path, item in
            Button {
                items.append("\(items.count)")
            } label: {
                ZStack {
                    Self.colors.randomElement()
                    
                    Text(item)
                }
                .frame(width: 200, height: 200)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .layout { _, environment in
                .grid(layoutEnvironment: environment,
                      layoutMode: .adaptive(withMinItemSize: 200),
                      itemSpacing: 60,
                      lineSpacing: 40,
                      itemSize: .estimated(200))
        }
        .animateChanges()
        .ignoresSafeArea(.all)
    }
}
```

</details>