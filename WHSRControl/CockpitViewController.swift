//
//  CockpitViewController.swift
//  WHSRControl
//
//  Created by Dirk Fröhling on 29.05.21.
//
//  Dieser ViewController zeigt aktuelle Werte des WHSR an.

import UIKit

class CockpitViewController: UIViewController, SPDelegate {
    
    // Klasse für BLE-Kommunikation mit dem WHSR
    private var peripheral: WHSRPeripheral!
    
    @IBOutlet weak var neigungswinkelLabel: UILabel!
    @IBOutlet weak var batterieLabel: UILabel!
    @IBOutlet weak var motorLinksSlider: UISlider!{
        didSet{
            motorLinksSlider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        }
    }
    @IBOutlet weak var motorRechtsSlider: UISlider!{
        didSet{
            motorRechtsSlider.transform = CGAffineTransform(rotationAngle: -CGFloat.pi/2)
        }
    }
    
    
    // MARK: - Callbacks für SPDelegate
    
    // Neue Werte erhalten
    func werteGeaendert() {
        // print("CockpitViewController: werteGeaendert", peripheral.phi)
        neigungswinkelLabel.text = String(format: "%.1f°", peripheral.phi)
        batterieLabel.text = String(format: "%.1fV", peripheral.batterie)
        motorLinksSlider.value = Float(peripheral.motorLinks)
        motorRechtsSlider.value = Float(peripheral.motorRechts)
    }
    
    // Mit BLE-Service verbunden
    func verbunden() {
        print("CockpitViewController: verbunden")
        motorLinksSlider.isEnabled = true
        motorRechtsSlider.isEnabled = true
    }
    
    // Von BLE-Service getrennt
    func getrennt() {
        print("CockpitViewController: getrennt")
        neigungswinkelLabel.text = "--"
        batterieLabel.text = "--"
        motorLinksSlider.isEnabled = false
        motorRechtsSlider.isEnabled = false
    }

    
    // MARK: - Initialisierung
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // WHSRPeripheral vom AppDelegate holen und uns selbst als Delegate registrieren
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        peripheral = appDelegate.theWHSRPeriperal
        peripheral.registerDelegate(self)
        
        // GUI initialisieren
        if peripheral.verbunden {
            neigungswinkelLabel.text = String(format: "%.1f°", peripheral.phi)
            batterieLabel.text = String(format: "%.1fV", peripheral.batterie)
            motorLinksSlider.isEnabled = true
            motorRechtsSlider.isEnabled = true
        } else {
            neigungswinkelLabel.text = "--"
            batterieLabel.text = "--"
            motorLinksSlider.isEnabled = false
            motorRechtsSlider.isEnabled = false
        }
    }
    
    @IBAction func motorLinksAction(_ sender: Any) {
        let geschwindigkeit = Int(motorLinksSlider.value)
        print("geschwindigkeit links:", geschwindigkeit)
        
        peripheral.setzeMotorLinks(geschwindigkeit)
    }
    
    @IBAction func motorRechtsAction(_ sender: Any) {
        let geschwindigkeit = Int(motorRechtsSlider.value)
        print("geschwindigkeit rechts:", geschwindigkeit)
        
        peripheral.setzeMotorRechts(geschwindigkeit)
    }


    /*
     // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
