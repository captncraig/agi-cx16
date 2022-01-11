## AGI-CX16

Work in progress agi interpreter for the cx16

### Memory Layout

Right now I am cheating a tiny bit by prefilling the bank ram into a file called BANKS. `preprocess.go` will generate this file from raw agi data. Eventually the cx16 app itself may parse the dir files, but this works for now.

All game data goes in banked ram. The first section of each bank is used for video buffers. Each bank has data for 1 line of video. First 160 bytes are used for the background data. Next 160 are for priority data. The next 160 are for foreground / rendered sprite data (someday). Then follows game objects.

Bank 1 has indexes for all of the game objects. consecutive 256 entry lookup tables:

- $a1e0 - picture ram banks
- $a2df - picture address low bytes
- $a3de - picture address high bytes

then follow other resource types.