%import cx16diskio
%import picture
%import palette

main {
    ubyte y
    ubyte x
    uword addr

    &ubyte[256] picdir_banks=$a1e0
    &ubyte[256] picdir_los=$a1e0+$ff
    &ubyte[256] picdir_his=$a1e0+$ff+$ff

    ubyte col3f = %1111
    ubyte col2a = %1010
    ubyte col15 = %0101

    sub setcolor(ubyte i,ubyte r,ubyte g,ubyte b){
        palette.set_color(i,mkword(r,g<<4 | b))
    }

    sub setupcolors(){
        setcolor(0,0,0,0)
        setcolor(1,0,0,col2a)
        setcolor(2,0,col2a,0)
        setcolor(3,0,col2a,col2a)
        setcolor(4,col2a,0,0)
        setcolor(5,col2a,0,col2a)
        setcolor(6,col2a,col15,0)
        setcolor(7,col2a,col2a,col2a)
        setcolor(8,col15,col15,col15)
        setcolor(9,col15,col15,col3f)
        setcolor($a,col15,col3f,col15)
        setcolor($b,col15,col3f,col3f)
        setcolor($c,col3f,col15,col15)
        setcolor($d,col3f,col15,col3f)
        setcolor($e,col3f,col3f,col15)
        setcolor($f,col3f,col3f,col3f)
    }

    ubyte picToDraw = 0
    ubyte drawing = 0

    sub start(){
        setupcolors()

        ; load data
        uword status = cx16diskio.load_raw(8,"banks",1,$A000)
        txt.print_uw(status)
        txt.nl()

        ; init video mode
        cx16.VERA_DC_VIDEO = (cx16.VERA_DC_VIDEO & %11001111) | %00100000      ; enable only layer 1
        cx16.VERA_DC_HSCALE = 64
        cx16.VERA_DC_VSCALE = 64
        cx16.VERA_L1_CONFIG = %00000110
        cx16.VERA_L1_MAPBASE = 0
        cx16.VERA_L1_TILEBASE = 0

        setup_irq()

        ; trigger gif
        @($9fb5) = 2

        mainthread:
        if drawing == 0{
            goto mainthread
        }
        picture.clear()
        picture.draw(picToDraw)
        drawing = 0
        goto mainthread
    }

    sub setup_irq(){
        picture.clear()
        render()
        cx16.set_irq(&my_irq, true)
        drawing = 1
        picToDraw = 14
    }

    sub my_irq(){
        render()
    }

    sub render(){
        if drawing{
            return
        }
        ; beggining of vram, increment of 1
        cx16.VERA_CTRL = %00000001
        cx16.VERA_ADDR_L = 0
        cx16.VERA_ADDR_M = 0
        cx16.VERA_ADDR_H = %00010000
        for y in 1 to 241 {
            @(0) = y
            addr = $a000
            for x in 0 to 159 {
                @(0) = y
                ubyte color = @(addr)
                addr++
                cx16.VERA_DATA1 = color
            }
        }
        
    }
}
