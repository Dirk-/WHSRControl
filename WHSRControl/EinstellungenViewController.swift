//
//  EinstellungenViewController.swift
//  WHSRControl
//
//  Created by Dirk Fröhling on 29.05.21.
//
//  In diesem ViewController können Einstellungen für den WHSR vorgenommen werden.

import UIKit

class EinstellungenViewController: UIViewController, SPDelegate {

    // Klasse für BLE-Kommunikation mit dem Scooter
    private var peripheral: WHSRPeripheral!

    @IBOutlet weak var blinkzeitSlider: UISlider!
    @IBOutlet weak var blinkzeitLabel: UILabel!
    @IBOutlet weak var kpSlider: UISlider!
    @IBOutlet weak var kpLabel: UILabel!
    @IBOutlet weak var kiSlider: UISlider!
    @IBOutlet weak var kiLabel: UILabel!
    @IBOutlet weak var kdSlider: UISlider!
    @IBOutlet weak var kdLabel: UILabel!
    @IBOutlet weak var speichernButton: UIButton!
    @IBOutlet weak var leSlider: UISlider!
    @IBOutlet weak var leLabel: UILabel!
    @IBOutlet weak var limitPhiSlider: UISlider!
    @IBOutlet weak var limitPhiLabel: UILabel!
    
    
    // MARK: - Callbacks für SPDelegate
    
    // Neue Werte erhalten
    func werteGeaendert() {
        // Diese Werte werden auch laufend aktualisiert, wenn der Neigungswinkel geändert wird – nicht gut.
        // TODO: In WHSRPeripheral die delegates unterschiedlich behandeln
        // print("EinstellungenViewController: werteGeaendert", peripheral.zeit, peripheral.kp, peripheral.ki, peripheral.kd)
        
        blinkzeitSlider.value = Float(peripheral.zeit)
        blinkzeitLabel.text = String(peripheral.zeit) + " ms"
        kpSlider.value = Float(peripheral.kp)
        kpLabel.text = String(format: "%.2f", peripheral.kp)
        kiSlider.value = Float(peripheral.ki)
        kiLabel.text = String(format: "%.2f", peripheral.ki)
        kdSlider.value = Float(peripheral.kd)
        kdLabel.text = String(format: "%.2f", peripheral.kd)
        leSlider.value = Float(peripheral.le)
        leLabel.text = String(format: "%.2f", peripheral.le)
        limitPhiSlider.value = Float(peripheral.limitPhi)
        limitPhiLabel.text = String(format: "%.0f°", peripheral.limitPhi)
    }
    
    // Mit BLE-Service verbunden
    func verbunden() {
        print("EinstellungenViewController: verbunden")
        
        blinkzeitSlider.isEnabled = true
        kpSlider.isEnabled = true
        kiSlider.isEnabled = true
        kdSlider.isEnabled = true
        leSlider.isEnabled = true
        limitPhiSlider.isEnabled = true
        speichernButton.isEnabled = true

        blinkzeitSlider.value = Float(peripheral.zeit)
        blinkzeitLabel.text = String(peripheral.zeit) + " ms"
        kpSlider.value = Float(peripheral.kp)
        kpLabel.text = String(format: "%.2f", peripheral.kp)
        kiSlider.value = Float(peripheral.ki)
        kiLabel.text = String(format: "%.2f", peripheral.ki)
        kdSlider.value = Float(peripheral.kd)
        kdLabel.text = String(format: "%.2f", peripheral.kd)
        leSlider.value = Float(peripheral.le)
        leLabel.text = String(format: "%.2f", peripheral.le)
        limitPhiSlider.value = Float(peripheral.limitPhi)
        limitPhiLabel.text = String(format: "%.0f°", peripheral.limitPhi)
    }
    
    // Von BLE-Service getrennt
    func getrennt() {
        print("EinstellungenViewController: getrennt")
        blinkzeitSlider.isEnabled = false
        kpSlider.isEnabled = false
        kiSlider.isEnabled = false
        kdSlider.isEnabled = false
        leSlider.isEnabled = false
        limitPhiSlider.isEnabled = false
        speichernButton.isEnabled = false

        blinkzeitLabel.text = "--"
        kpLabel.text = "--"
        kiLabel.text = "--"
        kdLabel.text = "--"
        leLabel.text = "--"
        limitPhiLabel.text = "--"
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
            blinkzeitSlider.isEnabled = true
            kpSlider.isEnabled = true
            kiSlider.isEnabled = true
            kdSlider.isEnabled = true
            leSlider.isEnabled = true
            limitPhiSlider.isEnabled = true
            speichernButton.isEnabled = true

            blinkzeitSlider.value = Float(peripheral.zeit)
            blinkzeitLabel.text = String(peripheral.zeit) + " ms"
            kpSlider.value = Float(peripheral.kp)
            kpLabel.text = String(format: "%.2f", peripheral.kp)
            kiSlider.value = Float(peripheral.ki)
            kiLabel.text = String(format: "%.2f", peripheral.ki)
            kdSlider.value = Float(peripheral.kd)
            kdLabel.text = String(format: "%.2f", peripheral.kd)
            leSlider.value = Float(peripheral.le)
            leLabel.text = String(format: "%.2f", peripheral.le)
            limitPhiSlider.value = Float(peripheral.limitPhi)
            limitPhiLabel.text = String(format: "%.0f°", peripheral.limitPhi)
        } else {
            blinkzeitSlider.isEnabled = false
            kpSlider.isEnabled = false
            kiSlider.isEnabled = false
            kdSlider.isEnabled = false
            leSlider.isEnabled = false
            limitPhiSlider.isEnabled = false
            speichernButton.isEnabled = false

            blinkzeitLabel.text = "--"
            kpLabel.text = "--"
            kiLabel.text = "--"
            kdLabel.text = "--"
            leLabel.text = "--"
            limitPhiLabel.text = "--"
        }
    }
    
    // MARK: - IB Actions

    @IBAction func blinkzeitChanged(_ sender: Any) {
        let zeit = Int(blinkzeitSlider.value)
        print("Zeit:", zeit)
        blinkzeitLabel.text = String(zeit) + " ms"
        
        peripheral.setzeZeit(zeit)
    }
    
    @IBAction func kpChanged(_ sender: Any) {
        let kp = kpSlider.value
        print("Kp:", kp)
        kpLabel.text = String(format: "%.2f", kp)
        
        peripheral.setzeKp(kp)
    }
    
    
     @IBAction func kiChanged(_ sender: Any) {
        let ki = kiSlider.value
        print("Ki:", ki)
        kiLabel.text = String(format: "%.2f", ki)
        
        peripheral.setzeKi(ki)
     }

    
    @IBAction func kdChanged(_ sender: Any) {
        let kd = kdSlider.value
        print("Kd:", kd)
        kdLabel.text = String(format: "%.2f", kd)
        
        peripheral.setzeKd(kd)
    }
    
    
    @IBAction func leChanged(_ sender: Any) {
        let le = leSlider.value
        print("le:", le)
        leLabel.text = String(format: "%.2f", le)
        
        peripheral.setzeLe(le)
    }
    
    
    @IBAction func limitPhiChanged(_ sender: Any) {
        let limitPhi = limitPhiSlider.value
        print("limitPhi:", limitPhi)
        limitPhiLabel.text = String(format: "%.0f°", limitPhi)
        
        peripheral.setzeLimitPhi(limitPhi)
    }
    
    
    @IBAction func speichernAction(_ sender: Any) {
        peripheral.setzeBefehl(1)
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
