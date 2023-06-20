//
//  ViewController.swift
//  BallBreak
//
//  Created by Georg on 08.07.18.
//  Copyright © 2018 Georg Sieber. All rights reserved.
//

import UIKit
import SQLite3
import CoreMotion

class ViewController: UIViewController {

    let motionManager = CMMotionManager()

    @IBOutlet weak var gameViewMain: GameView!
    @IBOutlet weak var btnHighscores: UIButton!
    @IBOutlet weak var btnWeb: UIButton!
    @IBAction func btnWeb(_ sender: UIButton) {
        if let url = URL(string: "http://georg-sieber.de") {
            UIApplication.shared.openURL(url)
        }
    }
    @IBAction func btnHighscores(_ sender: UIButton) {
        var highscoreString = ""
        var stmt:OpaquePointer?
        var counter = 0
        if sqlite3_prepare(db, "SELECT name, date, points FROM highscore ORDER BY points DESC LIMIT 10", -1, &stmt, nil) != SQLITE_OK {
            return
        }
        while sqlite3_step(stmt) == SQLITE_ROW {
            let name:String = String(cString: sqlite3_column_text(stmt, 0))
            let date:String = String(cString: sqlite3_column_text(stmt, 1))
            let points:Int = Int(sqlite3_column_int(stmt, 2))
            highscoreString += "[" + String(points) + "] " + name + "  (" + date + ")\n"
            if counter > 5 {
                highscoreString += "..."
                break
            }
            counter += 1
        }
        if (counter == 0) {
            highscoreString = "No highscores"
        }
        
        showDialog(title: "Highscores", text: highscoreString)
    }
    
    func showDialog(title:String, text:String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    func gameStarted() {
        btnWeb.isHidden = true
        btnHighscores.isHidden = true
    }
    func gameEnded() {
        btnWeb.isHidden = false
        btnHighscores.isHidden = false
    }
    
    func highscore(_score:Int) {
        var stmt:OpaquePointer?
        var maxPoints = 0
        if sqlite3_prepare(db, "SELECT points FROM highscore ORDER BY points DESC LIMIT 1", -1, &stmt, nil) != SQLITE_OK {
            print("prepare error")
            return
        }
        while sqlite3_step(stmt) == SQLITE_ROW {
            maxPoints = Int(sqlite3_column_int(stmt, 0))
        }
        if (maxPoints >= _score) {
            return
        }
        
        // show new highscore dialog
        let alert = UIAlertController(title: "New Highscore (\(_score))!", message: "Please enter your name", preferredStyle: .alert)
        alert.addTextField { (textField) in
            let defaults = UserDefaults.standard
            if let stringOne = defaults.string(forKey: "hs1name") {
                textField.text = stringOne
            }
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            let defaults = UserDefaults.standard
            defaults.set(textField?.text, forKey: "hs1name")
            
            var stmt:OpaquePointer?
            if sqlite3_prepare(self.db, "INSERT INTO highscore(name, date, points) VALUES (?,?,?)", -1, &stmt, nil) != SQLITE_OK {
                print("error prepare stmt")
            }
            let df = DateFormatter()
            df.dateFormat = "dd.MM.yy"
            let textFieldString = ((textField?.text) ?? "???") as NSString
            sqlite3_bind_text(stmt, 1, textFieldString.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, df.string(from: Date()), -1, nil)
            sqlite3_bind_int(stmt, 3, Int32(_score))
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("insert error")
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }

    var db: OpaquePointer?

    override func viewDidLoad() {
        super.viewDidLoad()
        gameViewMain.mainViewController = self
        
        initDB()
        initSensors()
    }
    
    let ALPHA:Float = 0.4;
    var mAccelX:Float = 0;
    var mAccelY:Float = 0;
    func applyLowPassFilter(input:Float, output:Float) -> Float {
        return output + ALPHA * (input - output)
    }
    
    func initSensors() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.05
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (accelerometerData, error) in
                self.gameViewMain.modX = CGFloat(
                    self.applyLowPassFilter(
                        input: Float((accelerometerData?.acceleration.x)!),
                        output: Float(self.gameViewMain.modX)
                    )
                )
                self.gameViewMain.modY = (-1)*CGFloat(
                    self.applyLowPassFilter(
                        input: Float((accelerometerData?.acceleration.y)!),
                        output: Float(self.gameViewMain.modY)
                    )
                )
            }
        }
    }
    
    func initDB() {
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("scores.sqlite")
        
        if(sqlite3_open(fileurl.path, &db) != SQLITE_OK) {
            print("error opening database "+fileurl.path)
        }
        if(sqlite3_exec(db, "CREATE TABLE IF NOT EXISTS highscore (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, date TEXT, points INTEGER)", nil,nil,nil) != SQLITE_OK) {
            print("error creating table: "+String(cString: sqlite3_errmsg(db)!))
        }
    }

}
