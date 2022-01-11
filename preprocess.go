package main

import (
	"log"
	"os"
)

var vols = [][]byte{
	mustRead("sqi/VOL.0"),
	mustRead("sqi/VOL.1"),
	mustRead("sqi/VOL.2"),
}
var picdir = mustRead("sqi/PICDIR")

func main() {
	pages := make([][]byte, 255)
	vbuf := make([]byte, 160)
	for i := range vbuf {
		vbuf[i] = 0x55
	}
	for y := 1; y <= 241; y++ {
		pages[y] = append(pages[y], vbuf...)
		pages[y] = append(pages[y], vbuf...)
		pages[y] = append(pages[y], vbuf...)
	}
	picPages := make([]byte, 255)
	picLos := make([]byte, 255)
	picHis := make([]byte, 255)
	for i, pic := range readDir(picdir) {
		l := len(pic)
		if l == 0 {
			continue
		}
		for y := byte(2); y < 255; y++ {
			if len(pages[y])+l < 8192 {
				picPages[i] = y
				addr := uint16(len(pages[y])) + 0xa000
				log.Println(i, y, len(pages[y]), len(pic))
				log.Printf("%x", addr)
				picLos[i] = byte(addr & 0xff)
				picHis[i] = byte(addr >> 8)
				pages[y] = append(pages[y], pic...)
				break
			}
		}
	}
	pages[1] = append(pages[1], picPages...)
	pages[1] = append(pages[1], picLos...)
	pages[1] = append(pages[1], picHis...)

	total := []byte{}
	for i, page := range pages[1:] {
		if len(page) == 0 || i > 5 {
			break
		}
		for len(page) < 8192 {
			page = append(page, 0x69)
		}
		total = append(total, page...)
	}
	log.Println(len(total), float64(len(total))/8192)
	log.Println(os.WriteFile("BANKS", total, 0664))
}

func mustRead(name string) []byte {
	dat, err := os.ReadFile(name)
	if err != nil {
		log.Fatal(err)
	}
	return dat
}

func readDir(dat []byte) [][]byte {
	entries := make([][]byte, 256)
	for i := 0; i < len(dat); i += 3 {
		if dat[i] == 0xff {
			continue
		}
		entryNum := i / 3
		volNum := dat[i] >> 4
		addr := (uint32(dat[i]&0x0f) << 16) + (uint32(dat[i+1]) << 8) + uint32(dat[i+2])
		//log.Printf("%d - %d - %x(%d)", entryNum, volNum, addr, addr)
		data := vols[volNum][addr : addr+5]
		leng := uint32(data[4])<<8 + uint32(data[3])
		log.Println(leng)
		entries[entryNum] = vols[volNum][addr+5 : addr+5+leng]
		//log.Println(len(entries[entryNum]), entries[entryNum])
	}
	return entries
}
