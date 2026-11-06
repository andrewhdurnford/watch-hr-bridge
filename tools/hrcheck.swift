// Mac-side verifier: acts like Zwift. Scans for a BLE Heart Rate sensor, connects,
// subscribes to 0x2A37 and prints each bpm. Proves the phone's BLE output works.
import Foundation
import CoreBluetooth

func out(_ s: String) {
    let line = "\(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)) \(s)\n"
    FileHandle.standardError.write(line.data(using: .utf8)!)
    if let h = FileHandle(forWritingAtPath: "/tmp/hrcheck.log") { h.seekToEndOfFile(); h.write(line.data(using: .utf8)!); h.closeFile() }
    else { try? line.write(toFile: "/tmp/hrcheck.log", atomically: true, encoding: .utf8) }
}

final class Checker: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var cm: CBCentralManager!
    var target: CBPeripheral?
    override init() { super.init(); cm = CBCentralManager(delegate: self, queue: nil) }

    func centralManagerDidUpdateState(_ c: CBCentralManager) {
        out("Bluetooth state \(c.state.rawValue) (5 = on)")
        if c.state == .poweredOn { c.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]); out("Scanning for heart rate sensors…") }
    }
    func centralManager(_ c: CBCentralManager, didDiscover p: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        let name = (advertisementData[CBAdvertisementDataLocalNameKey] as? String) ?? p.name ?? "?"
        let svcs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]) ?? []; if name.contains("Watch HR") || name.contains("iPhone") || svcs.contains(CBUUID(string: "180D")) { out("Found: \(name) svcs=\(svcs) rssi=\(rssi)") }
        guard target == nil, name.contains("Watch HR") else { return }
        target = p; p.delegate = self; c.stopScan(); c.connect(p)
    }
    func centralManager(_ c: CBCentralManager, didConnect p: CBPeripheral) { out("Connected"); p.discoverServices([CBUUID(string: "180D")]) }
    func peripheral(_ p: CBPeripheral, didDiscoverServices e: Error?) {
        for s in p.services ?? [] { p.discoverCharacteristics([CBUUID(string: "2A37")], for: s) }
    }
    func peripheral(_ p: CBPeripheral, didDiscoverCharacteristicsFor s: CBService, error: Error?) {
        for ch in s.characteristics ?? [] { p.setNotifyValue(true, for: ch); out("Subscribed to 2A37") }
    }
    func peripheral(_ p: CBPeripheral, didUpdateValueFor ch: CBCharacteristic, error: Error?) {
        guard let d = ch.value, d.count >= 2 else { return }
        let bpm = (d[0] & 1) == 0 ? Int(d[1]) : Int(d[1]) | Int(d[2]) << 8
        out("HR = \(bpm) bpm")
    }
}
let checker = Checker()
RunLoop.main.run(until: Date().addingTimeInterval(Double(CommandLine.arguments.dropFirst().first ?? "60") ?? 60))
out("done")
