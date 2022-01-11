%import textio
%import cx16diskio
%import conv

picture {

    ubyte[] colors = [$00,$11,$22,$33,$44,$55,$66,$77,$88,$99,$AA,$BB,$CC,$DD,$EE,$FF]
    ubyte pictureDraw
    ubyte pictureColor
    ubyte prioDraw
    ubyte prioColor

    ubyte bank
    uword addr

    ubyte instr

    ubyte x1
    ubyte y1
    ubyte x2
    ubyte y2

    sub clear(){
        ubyte y
        for y in 1 to 168{
            cx16.rambank(y)
            sys.memset($a000,160,$ff)
        }
    }

    sub draw(ubyte number){
        clear()
        cx16.rambank(1)
        bank = main.picdir_banks[number]
        addr = mkword(main.picdir_his[number],main.picdir_los[number])

        pictureDraw = 0
        prioDraw = 0
        while(1){
        instrloop:
            instr = next_i()
            when instr {
                $f0 -> {
                    pictureDraw = 1
                    instr = next_i()
                    pictureColor = colors[instr]
                }
                $f1 -> {
                    pictureDraw = 0
                }
                $f2 -> {
                    prioDraw = 1
                    instr = next_i()
                    prioColor = colors[instr]
                }
                $f3 -> {
                    prioDraw = 0
                }
                $f6 -> {
                    ; absolute lines
                    x1 = next_i()
                    y1 = next_i()
                    while 1{
                        if peek_i() & $f0 == $f0{
                            goto instrloop
                        }
                        x2 = next_i()
                        y2 = next_i()
                        line()
                        x1 = x2
                        y1 = y2
                    }
                }
                $f7 -> {
                    x1 = next_i()
                    y1 = next_i()
                    while 1{
                        if peek_i() & $f0 == $f0{
                            goto instrloop
                        }
                        ubyte rel = next_i()
                        word dy = rel & %111
                        if rel& %1000 != 0 {
					        dy *= -1
				        }
                        word dx = (rel & %01110000) >> 4
				        if rel & %10000000 != 0 {
					        dx *= -1
				        }
				        x2 = lsb((x1 as word) + dx)
				        y2 = lsb((y1 as word) + dy)
                        line()
                        x1 = x2
				        y1 = y2
                    }
                }
                $f8 -> {
                    ; fill
                    while 1{
                        if peek_i() & $f0 == $f0{
                            goto instrloop
                        }
                        x1 = next_i()
                        y1 = next_i()
                        fill()
                    }
                }
                $ff -> {
                    ;diskio.f_close_w()
                    return
                }
                else -> {
                    txt.print("unknown op: ")
                    txt.print_ubhex(instr,0)
                    txt.nl()
                    a: goto a
                }
            }
        }
    }

    sub next_i() -> ubyte{
        instr = peek_i()
        addr++
        return instr
    }

    sub peek_i() -> ubyte{
        cx16.rambank(bank)
        ubyte p = @(addr)
        return p
    }

    sub plot(ubyte x, ubyte y){
        if pictureDraw{
        cx16.rambank(y+1)
        @($a000+x) = pictureColor
        }
    }

    sub readpix(ubyte x, ubyte y) -> ubyte{
        cx16.rambank(y+1)
        return @($a000+x)
    }

    str l = @"L"
    str p = @"P"
    str f = @"F"
    str q = @"Q"
    str comma = @","
    str nl = "!"

    ;https://github.com/scummvm/scummvm/blob/master/engines/agi/picture.cpp#L681
    sub line(){
        word dx ;todo: reuse deltaX below
        word dy
        word x = x1 as word
        word y = y1 as word

        ; straight lines first
        if x1 == x2 or y1 == y2 {
            if x1 == x2{
                dx = 0
            }else if x2 > x1{
                dx = 1
            }else{
                dx = -1
            }
            if y1 == y2{
                dy = 0
            }else if y2 > y1{
                dy = 1
            }else{
                dy = -1
            }
            while x != x2 or y != y2{
                plot(lsb(x),lsb(y))
                x += dx
                y += dy
            }
            plot(lsb(x),lsb(y))
            return
        }

        word x1w = x1
        word x2w = x2
        word y1w = y1
        word y2w = y2
        word detDelta
        word errorX
        word errorY
        word stepY = 1
        word stepX = 1
        word deltaX = x2w - x1w
        word deltaY = y2w - y1w
        word i

        if deltaY < 0{
            stepY = -1
            deltaY = -deltaY
        }
        if deltaX < 0{
            stepX = -1
            deltaX = -deltaX
        }
        if deltaY > deltaX{
            i = deltaY
            detDelta = deltaY
		    errorX = deltaY / 2
		    errorY = 0
        }else{
            i = deltaX
            detDelta = deltaX
		    errorY = deltaX / 2
		    errorX = 0
        }
        
        plot(lsb(x),lsb(y))
        while i > 0{
            errorY += deltaY
		    if errorY >= detDelta {
			    errorY -= detDelta
			    y += stepY
		    }
            errorX += deltaX
		    if errorX >= detDelta {
			    errorX -= detDelta
			    x += stepX
		    }
            plot(lsb(x),lsb(y))
            i--
        }
    }

    uword sp
    sub fill(){
        sp = $a000
        ubyte count = 0
        if pictureDraw == 0{
            return
        }

        s_push(x1)
        s_push(y1)
        plot(x1,y1)
        ubyte prevx = $ff
        ubyte prevy = $ff
        while sp > $a000{
            y1 = s_pop()
            x1 = s_pop()
            if x1 > 0 {
                if(readpix(x1-1,y1) == $ff){
                    plot(x1-1,y1)
                    s_push(x1-1)
                    s_push(y1)
                }
            }
            if x1 < 159{
                if(readpix(x1+1,y1) == $ff){
                    plot(x1+1,y1)
                    s_push(x1+1)
                    s_push(y1)
                }
            }
            if y1 > 0 {
                if(readpix(x1,y1-1) == $ff){
                    plot(x1,y1-1)
                    s_push(x1)
                    s_push(y1-1)
                }
            }
            if y1 < 167 {
                if(readpix(x1,y1+1) == $ff){
                    plot(x1,y1+1)
                    s_push(x1)
                    s_push(y1+1)
                }
            }
        }
    }

    sub s_push(ubyte v){
        cx16.rambank($ff)
        @(sp) = v
        sp++
    }
    sub s_pop() -> ubyte{
        cx16.rambank($ff)
        sp--
        ubyte v = @(sp)
        return v
    }
}