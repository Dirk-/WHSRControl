//
//  WHSRPeripheral.swift
//  WHSRControl
//
//  Created by Dirk Fröhling on 13.05.21.
//

import Foundation
import UIKit
import CoreBluetooth

// Protokoll, dass die UIViewController befolgen müssen, um Bescheid über Änderungen zu bekommen
protocol SPDelegate {
    /// Wird vom WHSRPeripheral nach dem Verbinden aufgerufen
    func verbunden()

    /// Wird vom WHSRPeripheral nach dem Trennen aufgerufen
    func getrennt()

    /// Wird vom WHSRPeripheral nach dem Ändern von Werten aufgerufen
    func werteGeaendert()
}


class WHSRPeripheral: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {

    public static let farben = [1: "schwarz", 2: "rot", 3: "gelb", 4: "grün", 5: "blau", 6: "weiß", ]
    
    // UIViewController, die Bescheid bekommen müssen, wenn sich etwas geändert hat
    public var delegate1: SPDelegate?
    public var delegate2: SPDelegate?
    
    // Parameter, die übertragen werden
    public var farbe: Int = 0
    public var zeit: Int = 0
    public var motorLinks: Int = 0
    public var motorRechts: Int = 0
    public var phi: Float = 0
    public var batterie: Float = 0
    public var kp: Float = 0
    public var ki: Float = 0
    public var kd: Float = 0
    public var le: Float = 0
    public var limitPhi: Float = 0
    public var befehl: Int = 0

    public var verbunden: Bool = false
    
    // Die ViewController, die über Änderungen der Werte informiert werden müssen
    private var delegates: [SPDelegate] = []

    // UUIDs des Service und der Charakteristiken
    // UUIDs kann man z.B. hier generieren: https://www.uuidgenerator.net
    private static let whsrServiceUUID     = CBUUID.init(string: "3f8e8bbb-e0a0-4ed9-8fed-12ab21af7656")
    private static let farbeCharacteristicUUID   = CBUUID.init(string: "089e4562-8f38-4ddd-9cc7-39c7070474d9")
    private static let zeitCharacteristicUUID = CBUUID.init(string: "8063c28b-fe4d-4493-8c15-5a518040e32c")
    private static let motorLinksCharacteristicUUID = CBUUID.init(string: "91d54e09-1373-400d-bb97-c01e068e6056")
    private static let motorRechtsCharacteristicUUID = CBUUID.init(string: "08eea80b-ea5c-415b-8073-03a92a01aaf2")
    private static let phiCharacteristicUUID = CBUUID.init(string: "f5219e83-5dac-4adb-8418-44fe81777c2f")
    private static let batterieCharacteristicUUID = CBUUID.init(string: "c55fe8d0-4d14-4588-8463-f5c0c191d539")
    private static let kpCharacteristicUUID = CBUUID.init(string: "7b2909af-bafb-4bb7-b5d2-5625be3eb40e")
    private static let kiCharacteristicUUID = CBUUID.init(string: "d25ae7b8-d5b5-44f5-ae64-9fbbbb19d0dc")
    private static let kdCharacteristicUUID = CBUUID.init(string: "93050603-17fb-48cf-a185-da07390e74ae")
    private static let leCharacteristicUUID = CBUUID.init(string: "997af220-6aff-4c5a-8a9d-0da0d044445a")
    private static let limitPhiCharacteristicUUID = CBUUID.init(string: "14a1fae1-4564-4005-974e-b5dbe0aeb6da")
    private static let befehlCharacteristicUUID = CBUUID.init(string: "a5690458-f22d-48db-8901-f6c6f3d6bf38")

    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    // Charakteristiken
    private var farbeChar: CBCharacteristic?
    private var zeitChar: CBCharacteristic?
    private var motorLinksChar: CBCharacteristic?
    private var motorRechtsChar: CBCharacteristic?
    private var phiChar: CBCharacteristic?
    private var batterieChar: CBCharacteristic?
    private var kpChar: CBCharacteristic?
    private var kiChar: CBCharacteristic?
    private var kdChar: CBCharacteristic?
    private var leChar: CBCharacteristic?
    private var limitPhiChar: CBCharacteristic?
    private var befehlChar: CBCharacteristic?


    // MARK: - Initialisierung

    override init() {
        super.init()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    
    // MARK: - Delegate-Registrierung
    
    /// Wenn ein UIViewController über Wertänderungen informiert werden möchte, muss er sich hier registrieren. Dazu muss das Protokoll SPDelegate implementiert werden.
    /// - Parameter delegate: SPDelegate mit Informationsbedarf
    public func registerDelegate(_ delegate: SPDelegate) {
        delegates.append(delegate)
    }

    
    // MARK: - Methoden zur Parameteränderung
    
    /// Setzt Farbwert und schreibt ihn an die passende Charakteristik raus
    /// - Parameter farbe: Neue Farbe
    public func setzeFarbe(_ farbe: Int) {
        self.farbe = farbe
        let byte = UInt8(farbe)
        let data = withUnsafeBytes(of: byte) { Data($0) }
        writeValueToChar(withCharacteristic: farbeChar!, withValue: data)
    }

    
    /// Setzt Zeitwert und schreibt ihn an die passende Charakteristik raus
    /// - Parameter zeit: Neue Zeit
    public func setzeZeit(_ zeit: Int) {
        self.zeit = zeit
        let zeitInt = Int32(zeit)    // int ist 32 Bit auf Arduino Nano
        let data = withUnsafeBytes(of: zeitInt) { Data($0) }
        writeValueToChar(withCharacteristic: zeitChar!, withValue: data)
    }

    
    /// Setzt Geschwindigkeit für Motor links und schreibt ihn an die passende Charakteristik raus
    /// - Parameter geschwindigkeit: Neue Geschwindigkeit -254...255
    public func setzeMotorLinks(_ geschwindigkeit: Int) {
        self.motorLinks = geschwindigkeit
        let geschwInt = Int32(geschwindigkeit)    // int ist 32 Bit auf Arduino Nano
        let data = withUnsafeBytes(of: geschwInt) { Data($0) }
        writeValueToChar(withCharacteristic: motorLinksChar!, withValue: data)
    }

    
    /// Setzt Geschwindigkeit für Motor rechts und schreibt ihn an die passende Charakteristik raus
    /// - Parameter geschwindigkeit: Neue Geschwindigkeit -254...255
    public func setzeMotorRechts(_ geschwindigkeit: Int) {
        self.motorRechts = geschwindigkeit
        let geschwInt = Int32(geschwindigkeit)    // int ist 32 Bit auf Arduino Nano
        let data = withUnsafeBytes(of: geschwInt) { Data($0) }
        writeValueToChar(withCharacteristic: motorRechtsChar!, withValue: data)
    }

    
    /// Setzt Regelparameter Kp und schreibt ihn an die passende Charakteristik raus
    /// - Parameter kp: Neuer Wert
    public func setzeKp(_ kp: Float) {
        self.kp = kp
        let data = withUnsafeBytes(of: kp) { Data($0) }
        writeValueToChar(withCharacteristic: kpChar!, withValue: data)
    }


    /// Setzt Regelparameter Ki und schreibt ihn an die passende Charakteristik raus
    /// - Parameter ki: Neuer Wert
    public func setzeKi(_ ki: Float) {
        self.ki = ki
        let data = withUnsafeBytes(of: ki) { Data($0) }
        writeValueToChar(withCharacteristic: kiChar!, withValue: data)
    }


    /// Setzt Regelparameter Kd und schreibt ihn an die passende Charakteristik raus
    /// - Parameter kd: Neuer Wert
    public func setzeKd(_ kd: Float) {
        self.kd = kd
        let data = withUnsafeBytes(of: kd) { Data($0) }
        writeValueToChar(withCharacteristic: kdChar!, withValue: data)
    }


    /// Setzt Lenkempfindlichkeit und schreibt ihn an die passende Charakteristik raus
    /// - Parameter le: Neuer Wert
    public func setzeLe(_ le: Float) {
        self.le = le
        let data = withUnsafeBytes(of: le) { Data($0) }
        writeValueToChar(withCharacteristic: leChar!, withValue: data)
    }


    /// Setzt Grenzwinkel und schreibt ihn an die passende Charakteristik raus
    /// - Parameter limitPhi: Neuer Wert
    public func setzeLimitPhi(_ limitPhi: Float) {
        self.limitPhi = limitPhi
        let data = withUnsafeBytes(of: limitPhi) { Data($0) }
        writeValueToChar(withCharacteristic: limitPhiChar!, withValue: data)
    }


    /// Setzt Befehl und schreibt ihn an die passende Charakteristik raus
    /// - Parameter befehl: Auszuführender Befehl
    public func setzeBefehl(_ befehl: Int) {
        self.befehl = befehl
        let befehlInt = Int32(befehl)    // int ist 32 Bit auf Arduino Nano
        let data = withUnsafeBytes(of: befehlInt) { Data($0) }
        writeValueToChar(withCharacteristic: befehlChar!, withValue: data)
    }

    
    /// Schreiben eines neuen Wertes einer Charakteristik
    /// - Parameters:
    ///   - characteristic: Zu ändernde Charakteristik
    ///   - value: Neuer Wert
    private func writeValueToChar( withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        if characteristic.properties.contains(.write) && peripheral != nil {    // Wir dürfen schreiben
            peripheral.writeValue(value, for: characteristic, type: .withoutResponse)
        }
    }
    
    
    // MARK: - Callbacks
    
    /// Callback, der gerufen wird, wenn der Core Bluetooth Manager seinen Status ändert (z.B. beim Starten)
    /// - Parameter central: Bluetooth Manager
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central Status-Update")
        if central.state != .poweredOn {
            print("Wir sind nicht wach")
        } else {
            print("Scannen nach", WHSRPeripheral.whsrServiceUUID);
            centralManager.scanForPeripherals(withServices: [WHSRPeripheral.whsrServiceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    
    
    /// Callback, der gerufen wird, wenn ein Peripheral gefunden wurde
    /// - Parameters:
    ///   - central: Bluetooth Manager
    ///   - peripheral: Gefundenes Peripheral
    ///   - advertisementData: Dictionary mit Beschreibungsdaten des Peripheral
    ///   - RSSI: Signalstärke in dB
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // gefunden, also Scannen abstellen
        self.centralManager.stopScan()
        
        // Das ist jetzt unser Peripheral
        self.peripheral = peripheral
        // Wir kümmern uns um die Events
        self.peripheral.delegate = self
        
        // Verbinden
        self.centralManager.connect(self.peripheral, options: nil)
        
    }
    
    
    /// Callback, der gerufen wird, wenn wir uns erfolgreich verbunden haben
    /// - Parameters:
    ///   - central: Bluetooth Manager
    ///   - peripheral: Verbundenes Peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Verbunden mit ScooterController")
            peripheral.discoverServices([WHSRPeripheral.whsrServiceUUID])
        }
    }
    
    
    /// Callback, der gerufen wird, wenn ein Service gefunden wurde
    /// - Parameters:
    ///   - peripheral: Peripheral, zu dem die Services gehören
    ///   - error: Fehlerbeschreibung, falls die Servicesuche schiefgegangen ist
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == WHSRPeripheral.whsrServiceUUID {
                    print("ScooterController-Service gefunden")
                    
                    // Delegates informieren
                    delegates.forEach {
                        $0.verbunden()
                    }
                    verbunden = true    // Falls ein Delegate später nachfragt
                    
                    // Jetzt suchen wir die Charakteristiken
                    peripheral.discoverCharacteristics([WHSRPeripheral.farbeCharacteristicUUID,
                                                        WHSRPeripheral.zeitCharacteristicUUID,
                                                        WHSRPeripheral.motorLinksCharacteristicUUID,
                                                        WHSRPeripheral.motorRechtsCharacteristicUUID,
                                                        WHSRPeripheral.phiCharacteristicUUID,
                                                        WHSRPeripheral.batterieCharacteristicUUID,
                                                        WHSRPeripheral.kpCharacteristicUUID,
                                                        WHSRPeripheral.kiCharacteristicUUID,
                                                        WHSRPeripheral.kdCharacteristicUUID,
                                                        WHSRPeripheral.leCharacteristicUUID,
                                                        WHSRPeripheral.limitPhiCharacteristicUUID,
                                                        WHSRPeripheral.befehlCharacteristicUUID], for: service)
                    return
                }
            }
        }
    }
    
    
    /// Callback, der gerufen wird, wenn neue Werte vom Service geliefert werden
    /// - Parameters:
    ///   - peripheral: Peripheral, das die Werte liefert
    ///   - characteristic: Charakteristik, zu der die Werte gehören
    ///   - error: Fehlerbeschreibung, falls die Lesen eines Wertes schiefgegangen ist
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor  characteristic: CBCharacteristic, error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == WHSRPeripheral.whsrServiceUUID {
                    let data = characteristic.value
                    if characteristic.uuid == WHSRPeripheral.farbeCharacteristicUUID  {
                        let value = UInt8(data?.withUnsafeBytes {
                            $0.load(as: UInt8.self)
                        } ?? 1)
                        farbe = Int(value)
                    } else if characteristic.uuid == WHSRPeripheral.zeitCharacteristicUUID {
                         let value = Int32(data?.withUnsafeBytes {
                            $0.load(as: Int32.self)
                        } ?? 0)
                        zeit = Int(value)
                    } else if characteristic.uuid == WHSRPeripheral.motorLinksCharacteristicUUID {
                         let value = Int32(data?.withUnsafeBytes {
                            $0.load(as: Int32.self)
                        } ?? 0)
                        motorLinks = Int(value)
                    } else if characteristic.uuid == WHSRPeripheral.motorRechtsCharacteristicUUID {
                         let value = Int32(data?.withUnsafeBytes {
                            $0.load(as: Int32.self)
                        } ?? 0)
                        motorRechts = Int(value)
                    } else if characteristic.uuid == WHSRPeripheral.kpCharacteristicUUID {
                        let value = Float(data?.withUnsafeBytes {
                            $0.load(as: Float.self)
                        } ?? 0)
                        kp = Float(value)
                        print("Parameter Kp: ", kp)
                    } else if characteristic.uuid == WHSRPeripheral.kiCharacteristicUUID {
                        let value = Float(data?.withUnsafeBytes {
                            $0.load(as: Float.self)
                        } ?? 0)
                        ki = Float(value)
                        print("Parameter Ki: ", ki)
                    } else if characteristic.uuid == WHSRPeripheral.kdCharacteristicUUID {
                        let value = Float(data?.withUnsafeBytes {
                            $0.load(as: Float.self)
                        } ?? 0)
                        kd = Float(value)
                        print("Parameter Kd: ", kd)
                    } else if characteristic.uuid == WHSRPeripheral.limitPhiCharacteristicUUID {
                        let value = Float(data?.withUnsafeBytes {
                            $0.load(as: Float.self)
                        } ?? 0)
                        limitPhi = Float(value)
                        print("Parameter limitPhi: ", limitPhi)
                    } else if characteristic.uuid == WHSRPeripheral.leCharacteristicUUID {
                        let value = Float(data?.withUnsafeBytes {
                            $0.load(as: Float.self)
                        } ?? 0)
                        le = Float(value)
                        print("Parameter le: ", le)
                    } else if characteristic.uuid == WHSRPeripheral.phiCharacteristicUUID {
                         let value = Float(data?.withUnsafeBytes {
                            $0.load(as: Float.self)
                        } ?? 0)
                        phi = Float(value)
                    } else if characteristic.uuid == WHSRPeripheral.batterieCharacteristicUUID {
                         let value = Float(data?.withUnsafeBytes {
                            $0.load(as: Float.self)
                        } ?? 0)
                        batterie = Float(value)
                        print("Batterie: ", batterie)
                    }
                    // Delegates informieren
                    // TODO: Delegates unterschiedlich behandeln
                    delegates.forEach {
                        $0.werteGeaendert()
                    }
               }
            }
        }
    }
    
    
    /// Callback, der gerufen wird, wenn Charakteristiken gefunden wurden
    /// - Parameters:
    ///   - peripheral: Peripheral, das die Werte liefert
    ///   - service: Service, zu der die Charakteristik gehört
    ///   - error: Fehlerbeschreibung, falls das Suchen nach einer Charakteristik schiefgegangen ist
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == WHSRPeripheral.farbeCharacteristicUUID {
                    print("Farbe Charakteristik gefunden")
                    farbeChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.zeitCharacteristicUUID {
                    print("Zeit Charakteristik gefunden")
                    zeitChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.motorLinksCharacteristicUUID {
                    print("Motor Links Charakteristik gefunden")
                    motorLinksChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.motorRechtsCharacteristicUUID {
                    print("Motor Rechts Charakteristik gefunden")
                    motorRechtsChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.kpCharacteristicUUID {
                    print("Kp Charakteristik gefunden")
                    kpChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.kiCharacteristicUUID {
                    print("Ki Charakteristik gefunden")
                    kiChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.kdCharacteristicUUID {
                    print("Kd Charakteristik gefunden")
                    kdChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.leCharacteristicUUID {
                    print("le Charakteristik gefunden")
                    leChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.limitPhiCharacteristicUUID {
                    print("limitPhi Charakteristik gefunden")
                    limitPhiChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.befehlCharacteristicUUID {
                    print("Befehl Charakteristik gefunden")
                    befehlChar = characteristic
                } else if characteristic.uuid == WHSRPeripheral.phiCharacteristicUUID {
                    print("phi Charakteristik gefunden")
                    phiChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                } else if characteristic.uuid == WHSRPeripheral.batterieCharacteristicUUID {
                    print("Batterie Charakteristik gefunden")
                    batterieChar = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    
    /// Callback, der gerufen wird, wenn sich ein Peripheral verabschiedet
    /// - Parameters:
    ///   - central: Bluetooth Manager
    ///   - peripheral: Das getrennte Peripheral
    ///   - error: Fehlerbeschreibung, falls das Trennen schiefgegangen ist
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if peripheral == self.peripheral {
            print("Getrennt")
            
            // Delegates informieren
            delegates.forEach {
                $0.getrennt()
            }
            verbunden = false    // Falls ein Delegate später nachfragt

            self.peripheral = nil
            
            // Start scanning again
            print("Scannen nach", WHSRPeripheral.whsrServiceUUID);
            centralManager.scanForPeripherals(withServices: [WHSRPeripheral.whsrServiceUUID],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }

}
