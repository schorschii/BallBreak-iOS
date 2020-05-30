//
//  Vector2.swift
//  BallBreak
//
//  Created by Georg on 09.07.18.
//  Copyright © 2018 Georg Sieber. All rights reserved.
//

import UIKit

class Vector2 {
    var x:Float = 0;
    var y:Float = 0;
    var w:Int = 10;
    var h:Int = 10;
    var dirX:Float = 0;
    var dirY:Float = 0;
    var stepsMoved = 0;
    
    var r:CGFloat = 1;
    var g:CGFloat = 1;
    var b:CGFloat = 1;
    var a:Float = 1;

    init(_x:Float, _y:Float, _s:Int) {
        x = _x
        y = _y
        w = _s
        h = _s
        r = CGFloat((arc4random_uniform(600) + 400)) / 1000
        g = CGFloat((arc4random_uniform(600) + 400)) / 1000
        b = CGFloat((arc4random_uniform(600) + 400)) / 1000
    }
    init(_x:Float, _y:Float, _s:Int, _dirX:Float, _dirY:Float, _a:Float) {
        x = _x
        y = _y
        w = _s
        h = _s
        dirX = _dirX
        dirY = _dirY
        r = CGFloat((arc4random_uniform(600) + 400)) / 1000
        g = CGFloat((arc4random_uniform(600) + 400)) / 1000
        b = CGFloat((arc4random_uniform(600) + 400)) / 1000
        a = _a
    }

    func move() {
        x += dirX
        y += dirY
        stepsMoved += 1
    }
    func moveTo(_x:Float, _y:Float, factor:Float) {
        let dx:Float = Float(_x-x)
        let dy:Float = Float(_y-y)
        x += (dx * factor)
        y += (dy * factor)
    }
    
    func getRect() -> CGRect {
        return CGRect(x:Int(x),y:Int(y),width:w,height:h)
    }
}
