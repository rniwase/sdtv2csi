# sdtv2csi - SDTV to MIPI CSI-2 Video Decoder
Board for converting SDTV analog video to MIPI CSI-2 using Analog Devices ADV7280A-M.

![sdtv2csi topview](misc/sdtv2csi_frontview.jpg)
![sdtv2csi backview](misc/sdtv2csi_backview.jpg)

## Example of operation with Raspberry Pi and FFmpeg
Enable the camera interface with the raspi-config command.

```
$ sudo raspi-config
```
Select `3 Interface Options` -> `I1 Legacy Camera` -> `<Yes>`

Add the following line to `/boot/config.txt`

```
dtoverlay=adv728x-m,adv7280m=on
```

However, for RPi 2B+, Zero, and Zero W, add the following:
```
dtoverlay=adv728x-m,i2c_pins_28_29=on,adv7280m=on
```

Reboot the system and check for devices.
```
$ sudo reboot
$ sudo v4l2-ctl --all -d /dev/video0
```

Installing FFmpeg.
```
$ sudo apt update
$ sudo apt install ffmpeg
```

Example commands for video recording (Connect NTSC composite video signal to VIDEO_IN pin header AIN1-GND).
```
$ ffmpeg -an -video_size 640x480 -r 29.97 -pix_fmt yuv420p -i /dev/video0 -c:v rawvideo out.asf 
```
```
$ ffmpeg -an -video_size 720x480 -r 29.97 -i /dev/video0 -c:v rawvideo -vf realtime out.asf 
```

Example command for output to frame buffer.
```
$ sudo ffmpeg -an -video_size 640x480 -r 29.97 -i /dev/video0 -pix_fmt bgra -f fbdev /dev/fb0
```
