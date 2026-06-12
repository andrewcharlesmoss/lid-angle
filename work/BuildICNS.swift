import Foundation

struct IconMember {
    let type: String
    let fileName: String
}

let source = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.iconset")
let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().dropFirst().first ?? "Resources/AppIcon.icns")

let members = [
    IconMember(type: "ic07", fileName: "icon_128x128.png"),
    IconMember(type: "ic08", fileName: "icon_128x128@2x.png"),
    IconMember(type: "ic09", fileName: "icon_256x256@2x.png"),
    IconMember(type: "ic10", fileName: "icon_512x512@2x.png")
]

func bigEndianData(_ value: UInt32) -> Data {
    var value = value.bigEndian
    return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
}

var body = Data()
for member in members {
    let png = try Data(contentsOf: source.appendingPathComponent(member.fileName))
    guard let typeData = member.type.data(using: .macOSRoman), typeData.count == 4 else {
        fatalError("Invalid ICNS member type \(member.type)")
    }

    body.append(typeData)
    body.append(bigEndianData(UInt32(png.count + 8)))
    body.append(png)
}

var icns = Data()
icns.append("icns".data(using: .macOSRoman)!)
icns.append(bigEndianData(UInt32(body.count + 8)))
icns.append(body)
try icns.write(to: output)
