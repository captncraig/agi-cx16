sudo mount -o loop,rw,sync,offset=1048576 sdcard.img /media/sdcard
sudo cp BANKS /media/sdcard
ls -la /media/sdcard
sudo umount /media/sdcard