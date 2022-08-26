# CollectionView

A basic wrapper of `UICollectionView` to overcome `LazyVGrid/LazyHGrid` performance issues.

Influenced by [SwiftUICollection](https://github.com/defagos/SwiftUICollection) and [ASCollectionView](https://github.com/apptekstudios/ASCollectionView).

# Usage

Currently, `CollectionView` just acts to display items for performance improvements. Further enhancements may be implemented in the future.

<details>
<summary>iOS Example</summary>

```swift
struct ContentView: View {
    
    @State
    var items = (0..<100).map { "\($0)" }
    
    static let colors: [Color] = [.blue, .red, .green, .yellow, .purple, .cyan, .indigo, .mint, .orange]
    
    var body: some View {
        CollectionView(items: items) { indexPath, item, proxy in
            Button {
                if indexPath.row < 50 {
                    proxy.scrollTo(.bottom)
                } else {
                    proxy.scrollTo(.top)
                }
            } label: {
                ZStack {
                    Self.colors.randomElement()
                        .frame(height: 150)
                        .cornerRadius(10)
                    
                    Text(item)
                }
            }
        }
        .willReachEdge(insets: .init(top: 300, leading: 0, bottom: 300, trailing: 0)) { edge in
            print("Will reach edge: \(edge)")
        }
        .onEdgeReached { edge in
            print("Edge reached: \(edge)")
        }
        .layout { _, layoutEnvironment in
                .grid(layoutEnvironment: layoutEnvironment,
                      layoutMode: .adaptive(withMinItemSize: 100),
                      sectionInsets: .zero)
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
        .ignoresSafeArea()
    }
}
```
</details>

<details>
<summary>tvOS Example</summary>

```swift
struct ContentView: View {
    
    @State
    var items = (0..<15).map { "\($0)" }
    
    static let colors: [Color] = [.blue, .red, .green, .yellow, .purple, .cyan, .indigo, .mint, .orange]
    
    var body: some View {
        CollectionView(items: items) { _, item, _ in
            Button {
                items.append("\(items.count)")
            } label: {
                ZStack {
                    Self.colors.randomElement()
                        .frame(width: 200, height: 200)
                    
                    Text(item)
                }
            }
            .buttonStyle(CardButtonStyle())
        }
        .willReachEdge(insets: .init(top: 300, leading: 0, bottom: 300, trailing: 0)) { edge in
            print("Will reach edge: \(edge)")
        }
        .onEdgeReached { edge in
            print("Edge reached: \(edge)")
        }
        .layout { _, layoutEnvironment in
                .grid(layoutEnvironment: layoutEnvironment,
                      layoutMode: .adaptive(withMinItemSize: 200),
                      itemSpacing: 60,
                      lineSpacing: 40,
                      itemSize: .estimated(200))
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
        .ignoresSafeArea()
    }
}
```
</details>