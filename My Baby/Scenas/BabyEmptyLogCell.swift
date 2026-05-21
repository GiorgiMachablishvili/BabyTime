import UIKit
import SnapKit

// Shared empty-state cell used in Feeding, Sleep and Diaper "today" sections.
final class BabyEmptyLogCell: UICollectionViewCell {
    static let reuseId = "BabyEmptyLogCell"

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        let source = UIImage(named: "teddyBear")
        let iv = UIImageView(image: source?.removingWhiteBackground() ?? source)
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .clear
        contentView.addSubview(iv)
        iv.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(120 * Constraint.yCoeff)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let attrs = super.preferredLayoutAttributesFitting(layoutAttributes)
        attrs.frame.size.height = 200 * Constraint.yCoeff
        return attrs
    }
}

// MARK: - UIImage white background removal

private extension UIImage {
    /// Flood-fills from the four corners to erase any near-white background pixels.
    func removingWhiteBackground(threshold: UInt8 = 235) -> UIImage {
        guard let cgImage = cgImage else { return self }

        let width  = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow   = bytesPerPixel * width

        var raw = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let ctx = CGContext(
            data: &raw,
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return self }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // BFS flood-fill from all four corners
        var visited = [Bool](repeating: false, count: width * height)
        var queue   = [(Int, Int)]()
        queue.reserveCapacity(width * height / 4)
        queue.append(contentsOf: [(0,0),(width-1,0),(0,height-1),(width-1,height-1)])

        func isBackground(_ x: Int, _ y: Int) -> Bool {
            let o = y * bytesPerRow + x * bytesPerPixel
            return raw[o] >= threshold && raw[o+1] >= threshold && raw[o+2] >= threshold
        }

        var head = 0
        while head < queue.count {
            let (x, y) = queue[head]; head += 1
            guard x >= 0, x < width, y >= 0, y < height else { continue }
            let idx = y * width + x
            guard !visited[idx] else { continue }
            visited[idx] = true
            guard isBackground(x, y) else { continue }
            raw[y * bytesPerRow + x * bytesPerPixel + 3] = 0  // erase alpha
            queue.append((x-1, y)); queue.append((x+1, y))
            queue.append((x, y-1)); queue.append((x, y+1))
        }

        guard let newCG = ctx.makeImage() else { return self }
        return UIImage(cgImage: newCG, scale: scale, orientation: imageOrientation)
    }
}
