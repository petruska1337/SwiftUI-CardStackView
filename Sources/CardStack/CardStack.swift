import SwiftUI

public class CardStackViewModel<Data: RandomAccessCollection>: ObservableObject {
  @Published var currentIndex: Data.Index
  var data: Data

  public init(data: Data) {
    self.data = data
    self.currentIndex = data.startIndex
  }

  public func next() {
    self.currentIndex = self.data.index(after: self.currentIndex)
  }

}

public struct CardStack<Direction, ID: Hashable, Data: RandomAccessCollection, Content: View>: View
where Data.Index: Hashable {

  @Environment(\.cardStackConfiguration) private var configuration: CardStackConfiguration
  @ObservedObject var viewModel: CardStackViewModel<Data>

  private let direction: (Double) -> Direction?
  private let id: KeyPath<Data.Element, ID>
  private let onSwipe: (Data.Element, Direction) -> Void
  private let content: (Data.Element, Direction?, Bool) -> Content

  public init(
    direction: @escaping (Double) -> Direction?,
    viewModel: CardStackViewModel<Data>,
    id: KeyPath<Data.Element, ID>,
    onSwipe: @escaping (Data.Element, Direction) -> Void,
    @ViewBuilder content: @escaping (Data.Element, Direction?, Bool) -> Content
  ) {
    self.direction = direction
    self.viewModel = viewModel
    self.id = id
    self.onSwipe = onSwipe
    self.content = content
  }

  public var body: some View {
    ZStack {
      ForEach(viewModel.data.indices.reversed(), id: \.self) { index -> AnyView in
        let relativeIndex = self.viewModel.data.distance(
          from: self.viewModel.currentIndex, to: index)
        if relativeIndex >= 0 && relativeIndex < self.configuration.maxVisibleCards {
          return AnyView(self.card(index: index, relativeIndex: relativeIndex))
        } else {
          return AnyView(EmptyView())
        }
      }
    }
  }

  private func card(index: Data.Index, relativeIndex: Int) -> some View {
    CardView(
      direction: direction,
      isOnTop: relativeIndex == 0,
      onSwipe: { direction in
        self.onSwipe(self.viewModel.data[self.viewModel.currentIndex], direction)
        self.viewModel.next()
      },
      content: { direction in
        self.content(self.viewModel.data[index], direction, relativeIndex == 0)
          .offset(
            x: 0,
            y: CGFloat(relativeIndex) * self.configuration.cardOffset
          )
          .scaleEffect(
            1 - self.configuration.cardScale * CGFloat(relativeIndex),
            anchor: .bottom
          )
      }
    )
  }

}

extension CardStack {

  public init(
    direction: @escaping (Double) -> Direction?,
    data: Data,
    id: KeyPath<Data.Element, ID>,
    onSwipe: @escaping (Data.Element, Direction) -> Void,
    @ViewBuilder content: @escaping (Data.Element, Direction?, Bool) -> Content
  ) {
    self.init(
      direction: direction,
      viewModel: CardStackViewModel(data: data),
      id: id,
      onSwipe: onSwipe,
      content: content
    )
  }

}

extension CardStack where Data.Element: Identifiable, ID == Data.Element.ID {

  public init(
    direction: @escaping (Double) -> Direction?,
    viewModel: CardStackViewModel<Data>,
    onSwipe: @escaping (Data.Element, Direction) -> Void,
    @ViewBuilder content: @escaping (Data.Element, Direction?, Bool) -> Content
  ) {
    self.init(
      direction: direction,
      viewModel: viewModel,
      id: \Data.Element.id,
      onSwipe: onSwipe,
      content: content
    )
  }

  public init(
    direction: @escaping (Double) -> Direction?,
    data: Data,
    onSwipe: @escaping (Data.Element, Direction) -> Void,
    @ViewBuilder content: @escaping (Data.Element, Direction?, Bool) -> Content
  ) {
    self.init(
      direction: direction,
      data: data,
      id: \Data.Element.id,
      onSwipe: onSwipe,
      content: content
    )
  }

}

extension CardStack where Data.Element: Hashable, ID == Data.Element {

  public init(
    direction: @escaping (Double) -> Direction?,
    viewModel: CardStackViewModel<Data>,
    onSwipe: @escaping (Data.Element, Direction) -> Void,
    @ViewBuilder content: @escaping (Data.Element, Direction?, Bool) -> Content
  ) {
    self.init(
      direction: direction,
      viewModel: viewModel,
      id: \Data.Element.self,
      onSwipe: onSwipe,
      content: content
    )
  }

  public init(
    direction: @escaping (Double) -> Direction?,
    data: Data,
    onSwipe: @escaping (Data.Element, Direction) -> Void,
    @ViewBuilder content: @escaping (Data.Element, Direction?, Bool) -> Content
  ) {
    self.init(
      direction: direction,
      data: data,
      id: \Data.Element.self,
      onSwipe: onSwipe,
      content: content
    )
  }

}
