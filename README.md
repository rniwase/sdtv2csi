# sdtv2csi - SDTV to MIPI CSI-2 Video Decoder
Board for converting SDTV analog video to MIPI CSI-2 using Analog Devices ADV7280A-M.

![sdtv2csi topview](misc/sdtv2csi_frontview.jpg)
![sdtv2csi backview](misc/sdtv2csi_backview.jpg)

## Configuration example in Raspberry Pi 4
1. Get and run kernel patch installation scripts
```
wget https://github.com/rniwase/sdtv2csi/raw/master/rpi/install_patch.sh
sudo bash install_patch.sh
```

2. Set dtoverlay in config.txt
```
# for Raspberry Pi OS Bookworm:
sudo bash -c 'echo "dtoverlay=adv728x-m,adv7280m=1" >> /boot/firmware/config.txt'
# for Raspberry Pi OS Bullseye:
sudo bash -c 'echo "dtoverlay=adv728x-m,adv7280m=1" >> /boot/config.txt'
```

3. Reboot the system and check for devices.
```
sudo reboot
sudo v4l2-ctl --all -d /dev/video0
```

### Operation check by FFmpeg
1. Connect NTSC composite video signal to VIDEO_IN pin header AIN1-GND

2. Install FFmpeg
```
sudo apt update
sudo apt install ffmpeg
```

3. Video recording
```
# Record full video including blanking line
ffmpeg -an -video_size 720x507 -r 29.97 -i /dev/video0 -c:v rawvideo -vf realtime -t 5 out.asf
# Record video with blanking lines cropped
ffmpeg -an -video_size 720x507 -r 29.97 -i /dev/video0 -c:v rawvideo -vf realtime,crop=720:480:0:27 -t 5 out_crop.asf
```