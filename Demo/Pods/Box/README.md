# Box

This is a Swift microframework which implements `Box<T>` & `MutableBox<T>`, with implementations of `==`/`!=` where `T`: `Equatable`.

`Box` is typically used to work around limitations of value types:

- recursive `struct`s/`enum`s
- type-parameterized `enum`s where more than one `case` has a value

## Use

Wrapping & unwrapping a `Box`:

```swift
// Wrap:
let box = Box(1)

// Unwrap:
let value = box.value
```

Changing the value of a `MutableBox`:

```swift
// Mutation:
let mutableBox = MutableBox(1)
mutableBox.value = 2
```

Building a recursive value type:

```swift
struct BinaryTree {
	let value: Int
	let left: Box<BinaryTree>?
	let right: Box<BinaryTree>?
}
```

Building a parameterized `enum`:

```swift
enum Result<T> {
	case Success(Box<T>)
	case Failure(NSError)
}
```

See the sources for more details.

## Integration

1. Add this repo as a submodule in e.g. `External/Box`:
  
        git submodule add https://github.com/robrix/Box.git External/Box
2. Drag `Box.xcodeproj` into your `.xcworkspace`/`.xcodeproj`.
3. Add `Box.framework` to your target’s `Link Binary With Libraries` build phase.
4. You may also want to add a `Copy Files` phase which copies `Box.framework` (and any other framework dependencies you need) into your bundle’s `Frameworks` directory. If your target is a framework, you may instead want the client app to include `Box.framework`.
