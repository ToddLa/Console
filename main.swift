//
//  main.swift
//  Console
//
//  Created by Todd Laney on 6/3/16.
//  Copyright © 2016 Todd Laney. All rights reserved.
//

import Foundation

Console.clearscreen()
Console.cursorhome()
Console.background = .blue
Console.color = .white
Console.hidecursor()

func draw() {
    let size = Console.size
    
    Console.clearscreen()
    Console.cursorhome()

    Console.drawBox(width: size.width, height: size.height, color:.yellow, background:.blue, terminator:"")
    Console.drawBox(width: 20, height: 10, at:(10,10), color:.white, background:.red)
    Console.drawBox(width: 20, height: 10, at:(35,10), color:.white, background:.green)
    Console.drawBox(width: 20, height: 10, at:(60,10), color:.white, background:.black)
    
    Console.background = Console.Color(0,255,0)
    Console.color = Console.Color(255,64,255)
    Console.print("\(size.width)x\(size.height)", at:(2,2))
    
    Console.position = (2,3)
    if size.width > 0 {
        let w = size.width - 2
        for x in 0..<w {
            let f = Double(x) / Double(w)
            Console.background = .rgb(f,0,0)
            Console.print(" ", terminator: "")
        }
    
        Console.position = (2,4)
        for x in 0..<w {
            let f = Double(x) / Double(w)
            Console.background = .rgb(0,f,0)
            Console.print(" ", terminator: "")
        }
    
        Console.position = (2,5)
        for x in 0..<w {
            let f = Double(x) / Double(w)
            Console.background = .rgb(0,0,f)
            Console.print(" ", terminator: "")
        }
    
        Console.position = (2,6)
        for x in 0..<w {
            let f = Double(x) / Double(w)
            Console.background = .rgb(f,f,f)
            Console.print(" ", terminator: "")
        }
    
        Console.position = (2,7)
        for x in 0..<w {
            let f = Double(x) / Double(w)
            Console.background = .hsl(f * 360.0,1.0,0.5)
            Console.print(" ", terminator: "")
        }
    }
    
    Console.position = (30,2)
}

Console.print("HELLO", color:.red)
print(Console.position, Console.size)
draw()

func quit() {
    Console.reset()
    Console.clearscreen()
    Console.cursorhome()
    Console.showcursor()
    exit(0)
}

dispatch_signal(SIGINT) {
    print("SIGINT!")
    //quit()
}

dispatch_signal(SIGWINCH) {
    print("SIGWINCH!")
    draw()
}

_ = dispatch_timer(interval: 1.0 / 60.0) {
    let now = DispatchTime.now()
    let sec = Double(now.rawValue) / Double(NSEC_PER_SEC)
    Console.print("Timer \(String(format:"%3.3f", sec))", at:(20,2), color:.white, background:.red)
}

_ = dispatch_timer(interval: 1.0) {
    let now = DispatchTime.now()
    let sec = Double(now.rawValue) / Double(NSEC_PER_SEC)
    let w = Console.size.width - 2
    guard w > 0 else {return}
    Console.position = (2,7)
    for x in 0..<w {
        let f = Double(x) / Double(w)
        Console.background = .hsl(sec * 10.0 + (f * 360.0),1.0,0.5)
        Console.print(" ", terminator: "")
    }
}

var input = ""

dispatch_read(STDIN_FILENO) {
    Console.position = (40, 2)
    Console.background = .yellow
    Console.color = .black

    if let ch = Console.getch() {
        print("Input -> \(ch.debugDescription)", terminator:"\u{1B}[0K")
        input.append(ch)
        if ch == "q" {quit()}
        if ch == "\u{1B}" {input=""}
        Console.print(input.debugDescription, at:(40,3), terminator:"\u{1B}[0K")
    } else {
        print("Input -> NONE       ")
    }
}

dispatchMain()

