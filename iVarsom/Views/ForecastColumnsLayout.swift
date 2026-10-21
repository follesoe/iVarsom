import SwiftUI

/// A vertical fold crossing a view, in the view's coordinate space.
struct ColumnDivision: Equatable, Sendable {
    /// The fold's center.
    var center: CGFloat
    /// The fold's width, including the system's margin for interactive content.
    /// Zero (apart from margins) while iPhone Duo lies flat.
    var width: CGFloat
}

/// Lays out a forecast's two parts side by side when there is room, and stacked
/// otherwise.
///
/// The first subview is the reading column (summary and day picker), the second
/// the avalanche problems. Keeping the same two subviews in both arrangements
/// preserves their state when the width changes, such as when iPhone Duo
/// unfolds. When a vertical fold crosses the view, as in iPhone Duo's book pose,
/// the gap between the columns sits on the fold.
struct ForecastColumnsLayout: Layout {
    var division: ColumnDivision?
    var minimumColumnWidth: CGFloat
    var gap: CGFloat = 16
    /// Space between the parts when stacked, matching a VStack's default.
    var stackSpacing: CGFloat = 8

    /// The leading column's width and the trailing column's start, or nil to stack.
    func columns(width: CGFloat) -> (leadingWidth: CGFloat, trailingStart: CGFloat)? {
        guard width.isFinite else { return nil }
        if let division {
            let halfGap = max(division.width, gap) / 2
            let leadingWidth = division.center - halfGap
            let trailingStart = division.center + halfGap
            if leadingWidth >= minimumColumnWidth, width - trailingStart >= minimumColumnWidth {
                return (leadingWidth, trailingStart)
            }
            // A fold too close to an edge to split around: decide by width alone.
        }
        let leadingWidth = (width - gap) / 2
        guard leadingWidth >= minimumColumnWidth else { return nil }
        return (leadingWidth, leadingWidth + gap)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return stackedSize(proposal: proposal, subviews: subviews) }
        let width = proposal.width ?? .infinity
        guard let columns = columns(width: width) else {
            return stackedSize(proposal: proposal, subviews: subviews)
        }
        let leading = subviews[0].sizeThatFits(ProposedViewSize(width: columns.leadingWidth, height: nil))
        let trailing = subviews[1].sizeThatFits(
            ProposedViewSize(width: width - columns.trailingStart, height: nil))
        return CGSize(width: width, height: max(leading.height, trailing.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2, let columns = columns(width: bounds.width) else {
            placeStacked(in: bounds, subviews: subviews)
            return
        }
        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: bounds.minY), anchor: .topLeading,
            proposal: ProposedViewSize(width: columns.leadingWidth, height: nil))
        subviews[1].place(
            at: CGPoint(x: bounds.minX + columns.trailingStart, y: bounds.minY), anchor: .topLeading,
            proposal: ProposedViewSize(width: bounds.width - columns.trailingStart, height: nil))
    }

    private func stackedSize(proposal: ProposedViewSize, subviews: Subviews) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil)) }
        return CGSize(
            width: proposal.width ?? sizes.map(\.width).max() ?? 0,
            height: sizes.map(\.height).reduce(0, +) + stackSpacing * CGFloat(max(sizes.count - 1, 0)))
    }

    private func placeStacked(in bounds: CGRect, subviews: Subviews) {
        var y = bounds.minY
        for subview in subviews {
            let proposal = ProposedViewSize(width: bounds.width, height: nil)
            subview.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading, proposal: proposal)
            y += subview.sizeThatFits(proposal).height + stackSpacing
        }
    }
}

extension GeometryProxy {
    /// A vertical fold crossing this view at least `minimumInset` from either
    /// edge, such as iPhone Duo's hinge in book pose. Includes the fold while
    /// the device lies flat, so columns don't move as it folds.
    func verticalDivision(minimumInset: CGFloat) -> ColumnDivision? {
        #if os(iOS) && !targetEnvironment(macCatalyst)
            guard #available(iOS 27.1, *) else { return nil }
            let width = size.width
            return reservedRegions(kind: .division, options: .includeInactive)
                .map(\.frame)
                .first { frame in
                    frame.height > frame.width
                        && frame.midX >= minimumInset && frame.midX <= width - minimumInset
                }
                .map { ColumnDivision(center: $0.midX, width: $0.width) }
        #else
            return nil
        #endif
    }
}
