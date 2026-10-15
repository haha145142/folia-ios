import Foundation

enum LRCParser {
    private static let timestampPattern = #"\[(\d{1,3}):(\d{2})(?:\.(\d{1,3}))?\]"#
    private static let offsetPattern = #"\[offset:([+-]?\d+)\]"#

    static func parse(_ source: String) -> [LyricLine] {
        let normalized = source.replacingOccurrences(of: "\r\n", with: "\n")
        let offsetMilliseconds = firstCapture(in: normalized, pattern: offsetPattern)
            .flatMap(Int.init) ?? 0
        guard let regex = try? NSRegularExpression(pattern: timestampPattern) else { return [] }

        var parsed: [(time: TimeInterval, text: String, order: Int)] = []
        var order = 0

        for rawLine in normalized.components(separatedBy: .newlines) {
            let line = rawLine as NSString
            let range = NSRange(location: 0, length: line.length)
            let matches = regex.matches(in: rawLine, range: range)
            guard !matches.isEmpty else { continue }

            let lyricText = regex.stringByReplacingMatches(
                in: rawLine,
                range: range,
                withTemplate: ""
            ).trimmingCharacters(in: .whitespacesAndNewlines)

            for match in matches {
                guard match.numberOfRanges >= 3,
                      let minuteRange = Range(match.range(at: 1), in: rawLine),
                      let secondRange = Range(match.range(at: 2), in: rawLine),
                      let minutes = Double(rawLine[minuteRange]),
                      let seconds = Double(rawLine[secondRange]) else { continue }

                var fraction: Double = 0
                if match.numberOfRanges > 3,
                   match.range(at: 3).location != NSNotFound,
                   let fractionRange = Range(match.range(at: 3), in: rawLine) {
                    let digits = String(rawLine[fractionRange])
                    if let value = Double(digits) {
                        fraction = value / pow(10, Double(digits.count))
                    }
                }

                let timestamp = max(0, minutes * 60 + seconds + fraction + Double(offsetMilliseconds) / 1000)
                parsed.append((timestamp, lyricText, order))
                order += 1
            }
        }

        return parsed
            .sorted { lhs, rhs in
                lhs.time == rhs.time ? lhs.order < rhs.order : lhs.time < rhs.time
            }
            .enumerated()
            .map { LyricLine(id: $0.offset, time: $0.element.time, text: $0.element.text) }
    }

    private static func firstCapture(in source: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, range: range), match.numberOfRanges > 1,
              let captureRange = Range(match.range(at: 1), in: source) else { return nil }
        return String(source[captureRange])
    }
}
