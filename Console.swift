import Darwin
import Swift
import Foundation // only for replacingOccurances

public struct Console {
    public static let tty = isTTY()
    public static let ESC = "\u{1B}"
    public static let CSI = "\u{1B}["
    public static let OSC = "\u{1B}]"
    public static let BEL = "\u{7}]"
    
    public typealias Size = (width:Int, height:Int)
    public typealias Position = (x:Int, y:Int)
    
    //
    // ANSI xterm256 color
    //
    public struct Color {
        var rawValue:Int
        static let black = Color(0)
        static let red = Color(1)
        static let green = Color(2)
        static let brown = Color(3)
        static let blue = Color(4)
        static let magenta = Color(5)
        static let cyan = Color(6)
        static let gray = Color(7)
        static let darkGray = Color(8)
        static let brightRed = Color(9)
        static let brightGreen = Color(10)
        static let yellow = Color(11)
        static let brightBlue = Color(12)
        static let brightMagenta = Color(13)
        static let brightCyan = Color(14)
        static let white = Color(15)
        init(_ i:Int) {rawValue = i}
        init(_ r:Int,_ g:Int,_ b:Int) {
            if r==g && g==b {
                self.init(232 + (r * 24/256))
            } else {
                self.init(16 + 36*(r*6/256) + 6*(g*6/256) + (b*6/256))
            }
        }
        static func rgb(_ r:Double, _ g:Double, _ b:Double) -> Color {
            return Color(Int(r * 255.0), Int(g * 255.0), Int(b * 255.0))
        }
        var fg : String {return CSI + "38;5;\(rawValue)m"}
        var bg : String {return CSI + "48;5;\(rawValue)m"}
    }
    
    private static func isTTY() -> Bool {
        guard isatty(STDOUT_FILENO) != 0 else {return false}
        guard isatty(STDIN_FILENO) != 0 else {return false}
        guard let term = getenv("TERM") else {return false}
        let bad = ["dumb"]
        if bad.contains(String(cString: term)) {return false}
        enableRawMode()
        return true
    }
    
    private static func out(_ s:String) {if tty {Swift.print(s, terminator:"")}}
    private static func esc(_ s:String) {out(ESC + s)}
    private static func csi(_ s:String) {out(CSI + s)}
    private static func osc(_ s:String) {out(OSC + s)}
    
    public static func getcursor()  {csi("6n")}
    public static func savecursor()  {esc("7")}
    public static func restorecursor()  {esc("8")}
    public static func cleareos() {csi("0J")}
    public static func clearbos() {csi("1J")}
    public static func clearscreen() {csi("2J")}
    public static func hidecursor()  {csi("?25l")}
    public static func showcursor()  {csi("?25h")}
    public static func cursorhome()  {csi("H")}
    public static func cursorpos(_ x:Int, _ y:Int)  {csi("\(y);\(x)H")}
    public static func cursorup(_ n:Int = 1)  {csi("\(n)A")}
    public static func cursordn(_ n:Int = 1)  {csi("\(n)B")}
    public static func cursorrt(_ n:Int = 1)  {csi("\(n)C")}
    public static func cursorlf(_ n:Int = 1)  {csi("\(n)D")}
    public static func cleareol()  {csi("0K")}
    public static func clearbol()  {csi("1K")}
    public static func clearline() {csi("2K")}
    public static func settitle(_ s:String) {osc("0;\(s)" + BEL)}
    public static func normal() {csi("0m")}
    public static func bold(_ on:Bool=true) {csi(on ? "1m" : "21m" )}
    public static func underline(_ on:Bool=true) {csi(on ? "4m" : "24m" )}
    public static func reverse(_ on:Bool=true) {csi(on ? "7m" : "27m" )}
    public static func blink(_ on:Bool=true) {csi(on ? "5m" : "25m" )}
    public static func reset() {csi("0m"); csi("39m"); csi("49m")}
    public static func defaultfg() {csi("39m")}
    public static func defaultbg() {csi("49m")}
    
    public static var color:Color      {set {out(newValue.fg)} get {return .white}}
    public static var background:Color {set {out(newValue.bg)} get {return .black}}
    
    public static var size:Size {
        guard tty else {return (0,0)}
        savecursor()
        position = (9999, 9999)
        let pos = self.position
        restorecursor()
        return (pos.x,pos.y)
    }
    
    private static func disableRawMode() {
        var attr = termios()
        tcgetattr(STDOUT_FILENO, &attr)
        attr.c_lflag |= UInt(ICANON | ECHO)
        tcsetattr(STDOUT_FILENO, TCSANOW, &attr)
        write(STDOUT_FILENO, "\u{1B}[?25h", 6)
    }
    
    private static func enableRawMode() {
        var attr = termios()
        tcgetattr(STDOUT_FILENO, &attr)
        attr.c_lflag &= ~UInt(ICANON | ECHO)
        attr.c_cc.16 = 0 // VMIN  = 0
        attr.c_cc.17 = 5 // VTIME = 500ms
        tcsetattr(STDOUT_FILENO, TCSANOW, &attr)
        write(STDOUT_FILENO, "\u{1B}[?25l", 6)
        
        atexit() {Console.disableRawMode()}
        signal(SIGINT) {code in Console.disableRawMode()}
    }

    /*
    public static func kbhit() -> Bool {
        var cb = 0
        ioctl(STDIN_FILENO, FIONREAD, &cb);
        return cb != 0
    }
    */
    
    /*
    public static func getc() -> CChar? {
        var c = CChar(0)
        let len = read(fd, &c, 1)
        guard len == 1 else {return nil}
        return c
    }*/

    public static func getch() -> Character? {
        guard tty else {return nil}
        var buf = [UInt8](repeating:0, count: 5)
        var len = read(STDOUT_FILENO, &buf, 1)
        guard len > 0 else {return nil}
        /* read extra bytes to build a single UTF8 codepoint */
        if ((buf[0] & 0xE0) == 0xC0) {len = 2}
        if ((buf[0] & 0xF0) == 0xE0) {len = 3}
        if ((buf[0] & 0xF8) == 0xF0) {len = 4}
        if (len > 1) {len = read(STDOUT_FILENO, &buf[1], len-1)+1}
        guard len > 0 else {return nil}
        return Character(String(cString: buf))
    }
    
    private static func setPosition(_ pos:Position) {
        csi("\(pos.y);\(pos.x)H")
    }
    private static func getPosition() -> Position {
        guard tty else {return (0,0)}
        
        fflush(__stdoutp)
        
        // send getcursor cmd to terminal
        guard write(STDOUT_FILENO, "\u{1B}[6n", 4) == 4 else {return (0,0)}
        
        // read back cursor position
        var buf = [CChar](repeating: 0, count: 16)
        guard read(STDOUT_FILENO, &buf, buf.count-1) > 0 else {return (0,0)}
        
        // parse out x,y from "ESC[yyy;xxxR"
        let str = String(cString: buf)
        guard str.hasPrefix("\u{1B}[") else {return (0,0)}
        guard str.hasSuffix("R") else {return (0,0)}
        guard let idx = str.firstIndex(of:";") else {return (0,0)}
        let y = Int(str[str.index(str.startIndex, offsetBy:2)..<idx]) ?? 0
        let x = Int(str[str.index(after:idx)..<str.index(before:str.endIndex)]) ?? 0
        return (x,y)
    }
    
    public static var position:Position {
        set {setPosition(newValue)}
        get {return getPosition()}
    }
    public static func print(_ str:String, at:Position? = nil, color:Color? = nil, background:Color? = nil, terminator:String = "\n") {
        var str = str
        var terminator = terminator
        
        guard tty else {return Swift.print(str, terminator:terminator)}

        if let c = color {self.color = c}
        if let c = background {self.background = c}

        if let pos = at {
            self.position = pos
            if (pos.x > 1) {
                let nl = "\n\u{1B}[\(pos.x-1)C"
                str = str.replacingOccurrences(of: "\n", with:nl)
                terminator = terminator.replacingOccurrences(of: "\n", with:nl)
            }
        }
        
        return Swift.print(str, terminator:terminator)
    }
}

extension Console.Color {
    static func hsl(_ h:Double, _ s:Double, _ l:Double) -> Console.Color {
        let h = fmod(h, 360.0)
        let c = (1 - abs(2.0 * l - 1.1)) * s
        let x = c * (1 - abs(fmod((h/60.0), 2.0) - 1.0))
        let m = l - (c / 2)
        switch h {
        case ..<60.0:  return .rgb(c+m, x+m, m)
        case ..<120.0: return .rgb(x+m, c+m, m)
        case ..<180.0: return .rgb(m, c+m, x+m)
        case ..<240.0: return .rgb(m, x+m, c+m)
        case ..<300.0: return .rgb(x+m, m, c+m)
        default:       return .rgb(c+m, m, x+m)
        }
    }
}

extension Console {
    public static func drawBox(width:Int, height:Int, at:Position? = nil, color:Color? = nil, background:Color? = nil, terminator:String = "\n") {
        var nl = "\n"
        
        if let pos = at, tty {
            self.position = pos
            if (pos.x > 1) {nl += "\u{1B}[\(pos.x-1)C"}
        }
        
        if let n = color {self.color = n}
        if let n = background {self.background = n}
        
        guard width > 0 && height > 0 else {print("", terminator:terminator); return}
        guard width > 1 && height > 1 else {print("+", terminator:terminator); return}
        guard width > 2 && height > 2 else {print("++" + nl + "++", terminator:terminator); return}
        
        //let sym = tty ? "┌─┐│ │└─┘" : "+-+| |+-+"
        let sym = tty ? "╭─╮│ │╰─╯" : "+-+| |+-+"
        let map = sym.map{String($0)}
        
        print(map[0] + String(repeating: map[1], count: width-2) + map[2], terminator:nl)
        for _ in 1...(height-2) {
            print(map[3] + String(repeating: map[4], count: width-2) + map[5], terminator:nl)
        }
        print(map[6] + String(repeating: map[7], count: width-2) + map[8], terminator:terminator)
    }
}




