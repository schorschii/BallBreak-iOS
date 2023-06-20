//
//  GameView.swift
//  BallBreak
//
//  Created by Georg on 08.07.18.
//  Copyright © 2018 Georg Sieber. All rights reserved.
//

import UIKit

class GameView: UIView {

    var mainViewController:ViewController? = nil;

    var mouseX:Float = 0
    var mouseY:Float = 0
    var mouseRect:Vector2 = Vector2(_x: 0, _y: 0, _s: 0);
    var ballAmount = 1;
    var particleAmount = 10;
    var particleSize = 5;
    var balls = [Vector2]()
    var particles = [Vector2]()
    var boxes = [Vector2]()
    var gameRunning:Bool = false;
    var gameJustStarted:Bool = true;
    var gameBorder = 35;
    var pointFontSize = 10;
    var pointFontSizeMax = 120;
    var modX:CGFloat = 0
    var modY:CGFloat = 0
    let modFactor:CGFloat = 28
    
    var t = Timer()
    
    func realRect(orig: CGRect) -> CGRect {
        return CGRect(x:orig.minX+(modX*modFactor), y:orig.minY+(modY*modFactor), width:orig.width, height:orig.height)
    }
    
    override func layoutSubviews() {
        if !t.isValid {
            t = Timer.scheduledTimer(timeInterval: 0.038,
                                 target:self,
                                 selector: #selector(GameView.upd),
                                 userInfo: nil,
                                 repeats:true)
        }
    }
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // clear canvas
        UIColor.black.set()
        UIBezierPath(rect: rect).fill()
        
        // balls
        for ball in balls {
            UIColor(red:CGFloat(ball.r), green:CGFloat(ball.g), blue:CGFloat(ball.b), alpha:255).set()
            UIBezierPath(ovalIn: ball.getRect()).fill()
        }
        // particles
        for particle in particles {
            UIColor(red:CGFloat(particle.r), green:CGFloat(particle.g), blue:CGFloat(particle.b), alpha:CGFloat(particle.a)).set()
            UIBezierPath(ovalIn: particle.getRect()).fill()
        }
        // boxes
        for box in boxes {
            UIColor(red:CGFloat(box.r), green:CGFloat(box.g), blue:CGFloat(box.b), alpha:255).set()
            UIBezierPath(rect: realRect(orig:box.getRect())).fill()
        }

        // cursor cross
        UIColor.white.set()
        UIBezierPath(rect: CGRect(x:Int(mouseX-10),y:Int(mouseY-2),width:20,height:4))
        .fill()
        UIBezierPath(rect: CGRect(x:Int(mouseX-2),y:Int(mouseY-10),width:4,height:20))
            .fill()
        
        let paragraphStyleCenter = NSMutableParagraphStyle()
        paragraphStyleCenter.alignment = NSTextAlignment.center

        let gtStringRect = CGRect(x: 0, y: self.frame.height/3, width: self.frame.width, height: self.frame.height)

        if(gameRunning) {
            if (pointFontSize < pointFontSizeMax) {
                let gameText = ballAmount.description
                let gtattributes = [
                    NSAttributedString.Key.paragraphStyle: paragraphStyleCenter,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(pointFontSize)),
                    NSAttributedString.Key.foregroundColor: UIColor.init(red: 1, green: 1, blue: 1, alpha: 1-CGFloat(CGFloat(pointFontSize)/CGFloat(pointFontSizeMax)))
                ]
                let attributedString = NSAttributedString(string: gameText, attributes: gtattributes)
                attributedString.draw(in: gtStringRect)
                pointFontSize += 2
            }
        } else {
            if(!gameJustStarted) {
                UIColor(red:1, green:0, blue:0, alpha:0.75).set()
                UIBezierPath(rect: rect).fill()
            }
            
            let attributes = [
                NSAttributedString.Key.paragraphStyle: paragraphStyleCenter,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 26.0),
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
            var myText = "Game Over\n"
            if(gameJustStarted) {
                myText = "Tap to start"
            }
            var attributedString = NSAttributedString(string: myText, attributes: attributes)
            let stringRect = CGRect(x: 0, y: self.frame.height/4, width: self.frame.width, height: self.frame.height)
            attributedString.draw(in: stringRect)
            
            if(!gameJustStarted) {
                let gameText = ballAmount.description
                let gtattributes = [
                    NSAttributedString.Key.paragraphStyle: paragraphStyleCenter,
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: CGFloat(Double(pointFontSizeMax)*0.75)),
                    NSAttributedString.Key.foregroundColor: UIColor.init(red: 1, green: 1, blue: 1, alpha: 1)
                ]
                attributedString = NSAttributedString(string: gameText, attributes: gtattributes)
                attributedString.draw(in: gtStringRect)
                pointFontSize += 2
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if(gameRunning == false) {
                startGame()
            }
            let position = touch.location(in: self)
            mouseX = Float(position.x)
            mouseY = Float(position.y)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if(gameRunning) {
                let position = touch.location(in: self)
                mouseX = Float(position.x)
                mouseY = Float(position.y)
            }
        }
    }

    @objc func upd() {
        mouseRect = Vector2(_x:mouseX-10, _y:mouseY-10, _s:20)

        if(gameRunning) {
            // move balls
            for (i,ball) in balls.enumerated().reversed() {
                if(ball.getRect().intersects(mouseRect.getRect())) {
                    gameOver()
                    return
                }
                
                ball.moveTo(_x: mouseX, _y: mouseY, factor: 0.065)
                for box in boxes {
                    if(ball.getRect().intersects(realRect(orig:box.getRect()))) {
                        balls.remove(at:i)
                        for _ in 1...particleAmount {
                            particles.append(Vector2(_x:ball.x, _y:ball.y, _s: particleSize, _dirX:Float(movementRand()), _dirY:Float(movementRand()),
                                _a:0.75))
                        }
                        break
                    }
                }
            }
            for box in boxes {
                if(realRect(orig:box.getRect()).intersects(mouseRect.getRect())) {
                    gameOver()
                    return
                }
            }
            for (i,particle) in particles.enumerated().reversed() {
                particle.move()
                if(particle.stepsMoved > 100) {
                    particles.remove(at:i)
                }
            }
        }

        if(balls.count == 0 && gameRunning) {
            ballAmount += 1
            startRound()
        }

        self.setNeedsDisplay()
    }
    
    func movementRand() -> Int {
        var rand = 0
        while rand == 0 {
            rand = Int(arc4random_uniform(10)) - 5
        }
        return rand
    }
    
    func gameOver() {
        gameRunning = false;
        mainViewController?.gameEnded()
        
        mainViewController?.highscore(_score: ballAmount)
        
        self.setNeedsDisplay()
    }
    
    func startGame() {
        mainViewController?.gameStarted()
        ballAmount = 1
        gameJustStarted = false
        particles = [Vector2]()
        startRound()
    }
    
    func startRound() {
        gameRunning = true
        pointFontSize = 10
        
        let ballSize:Int = Int(round(min(self.frame.width, self.frame.height) / 38))
        particleSize = Int(ballSize/2)
        let boxSize:Int = Int(round(min(self.frame.width, self.frame.height) / 33))

        balls = [Vector2]()
        boxes = [Vector2]()
        
        for _ in 1...ballAmount {
            let whichBorder = arc4random_uniform(4)
            if(whichBorder == 0) {
                balls.append(Vector2(_x:Float(arc4random_uniform(UInt32(self.frame.width))), _y:0, _s:ballSize))
            } else if(whichBorder == 1) {
                balls.append(Vector2(_x:Float(self.frame.width), _y:Float(arc4random_uniform(UInt32(self.frame.height))), _s:ballSize))
            } else if(whichBorder == 2) {
                balls.append(Vector2(_x:Float(arc4random_uniform(UInt32(self.frame.width))), _y:Float(self.frame.height), _s:ballSize))
            } else if(whichBorder == 3) {
                balls.append(Vector2(_x:0, _y:Float(arc4random_uniform(UInt32(self.frame.height))), _s:ballSize))
            }
            
            var validBoxPosition:Bool = false;
            var newBoxX:Float = 0;
            var newBoxY:Float = 0;
            while(!validBoxPosition) {
                newBoxX = Float(arc4random_uniform(UInt32(self.frame.width-CGFloat(gameBorder*2))))+Float(gameBorder)
                newBoxY = Float(arc4random_uniform(UInt32(self.frame.height-CGFloat(gameBorder*2))))+Float(gameBorder)
                let pruefRect:CGRect = CGRect(x:Int(newBoxX)-(boxSize*3), y:Int(newBoxY)-(boxSize*3), width:(boxSize*3)*2, height:(boxSize*3)*2)
                if(!mouseRect.getRect().intersects(pruefRect)) {
                    validBoxPosition = true
                }
            }
            boxes.append(Vector2(_x:newBoxX, _y:newBoxY, _s:boxSize))
        }
    }

}
