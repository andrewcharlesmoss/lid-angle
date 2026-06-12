import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Resources/DoorCreak.wav")
let sampleRate = 44_100
let duration = 1.05
let frameCount = Int(Double(sampleRate) * duration)

struct Generator {
    var state: UInt64 = 0xC0DEC0FFEE

    mutating func noise() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let value = Double((state >> 33) & 0x7fff_ffff) / Double(0x7fff_ffff)
        return value * 2 - 1
    }
}

var random = Generator()
var samples = [Int16]()
samples.reserveCapacity(frameCount)

for index in 0..<frameCount {
    let t = Double(index) / Double(sampleRate)
    let progress = t / duration

    let attack = min(progress / 0.05, 1)
    let release = pow(max(0, 1 - progress), 1.2)
    let envelope = attack * release

    let wobble = 1 + 0.22 * sin(2 * .pi * 2.1 * t) + 0.08 * sin(2 * .pi * 6.7 * t)
    let lowGroanFrequency = 63 + 28 * sin(2 * .pi * 0.74 * t)
    let lowGroan = sin(2 * .pi * lowGroanFrequency * wobble * t)

    let scrapeFrequency = 210 + 95 * sin(2 * .pi * 1.8 * t)
    let scrape = sin(2 * .pi * scrapeFrequency * t + 0.9 * sin(2 * .pi * 19 * t))
    let raspGate = pow(abs(sin(2 * .pi * 11.5 * t)), 4)
    let rasp = (0.5 * scrape + 0.5 * random.noise()) * raspGate

    let squealEnvelope = exp(-pow((progress - 0.63) / 0.16, 2))
    let squealFrequency = 690 + 180 * sin(2 * .pi * 3.3 * t)
    let squeal = sin(2 * .pi * squealFrequency * t) * squealEnvelope

    let knockEnvelope = exp(-pow((progress - 0.18) / 0.035, 2)) + 0.7 * exp(-pow((progress - 0.47) / 0.045, 2))
    let knock = random.noise() * knockEnvelope

    let value = (
        0.62 * lowGroan +
        0.42 * rasp +
        0.28 * squeal +
        0.24 * knock
    ) * envelope * 0.44
    let clipped = max(-1, min(1, value))
    samples.append(Int16(clipped * Double(Int16.max)))
}

func littleEndianData<T: FixedWidthInteger>(_ value: T) -> Data {
    var value = value.littleEndian
    return Data(bytes: &value, count: MemoryLayout<T>.size)
}

var data = Data()
let byteRate = UInt32(sampleRate * 2)
let dataSize = UInt32(samples.count * 2)

data.append("RIFF".data(using: .ascii)!)
data.append(littleEndianData(UInt32(36) + dataSize))
data.append("WAVE".data(using: .ascii)!)
data.append("fmt ".data(using: .ascii)!)
data.append(littleEndianData(UInt32(16)))
data.append(littleEndianData(UInt16(1)))
data.append(littleEndianData(UInt16(1)))
data.append(littleEndianData(UInt32(sampleRate)))
data.append(littleEndianData(byteRate))
data.append(littleEndianData(UInt16(2)))
data.append(littleEndianData(UInt16(16)))
data.append("data".data(using: .ascii)!)
data.append(littleEndianData(dataSize))

for sample in samples {
    data.append(littleEndianData(sample))
}

try FileManager.default.createDirectory(
    at: output.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try data.write(to: output)
