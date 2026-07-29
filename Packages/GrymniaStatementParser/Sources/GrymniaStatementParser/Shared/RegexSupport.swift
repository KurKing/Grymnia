import Foundation

func match(_ pattern: String, in value: String) -> [String: String]? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
        return nil
    }
    let range = NSRange(value.startIndex..<value.endIndex, in: value)
    guard let result = regex.firstMatch(in: value, range: range) else {
        return nil
    }

    var output: [String: String] = [:]
    for name in ["operation", "posting", "date", "mcc", "merchant", "amount", "currency", "suffix", "value"] {
        let captureRange = result.range(withName: name)
        guard captureRange.location != NSNotFound, let swiftRange = Range(captureRange, in: value) else {
            continue
        }
        output[name] = String(value[swiftRange])
    }
    return output
}

func normalizedCurrency(_ raw: String?, fallback: String) -> String {
    guard let raw else { return fallback }
    let upper = raw.uppercased()
    if upper.contains("ГРН") { return "UAH" }
    return upper
}
