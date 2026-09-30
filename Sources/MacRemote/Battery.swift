import Foundation
import IOKit.ps

enum Battery {
    /// {"hasBattery": Bool, "percent": Int, "charging": Bool, "plugged": Bool}
    static func status() -> [String: Any] {
        let info = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let list = IOPSCopyPowerSourcesList(info).takeRetainedValue() as [CFTypeRef]
        for src in list {
            guard let d = IOPSGetPowerSourceDescription(info, src)?.takeUnretainedValue() as? [String: Any],
                  d[kIOPSTypeKey] as? String == kIOPSInternalBatteryType else { continue }
            let cur = d[kIOPSCurrentCapacityKey] as? Int ?? 0
            let max = d[kIOPSMaxCapacityKey] as? Int ?? 100
            return [
                "hasBattery": true,
                "percent": max > 0 ? cur * 100 / max : cur,
                "charging": d[kIOPSIsChargingKey] as? Bool ?? false,
                "plugged": d[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue,
            ]
        }
        return ["hasBattery": false]
    }
}
