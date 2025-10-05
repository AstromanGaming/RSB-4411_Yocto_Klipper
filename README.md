# RSB-4411_Yocto_Klipper

## Warning: Not finish and WIP!

Raise3D E2 All-In-One Klipper

### PC Minimun Requirement:
- CPU: Quad-core (4 cores) processor (or higher very recommended for better compile performance)
- Memory: 16GB RAM (or higher recommended for better task performance)
- Disk Space: 500GB-1TB (SSD is suggested for better performance)
- OS: Ubuntu 22.04.X LTS (Linux Distro with Ubuntu 22.04.X LTS with base it's okay, but not recommended.)
- GPU*: N/A (if you're don't use GUI)

### PC Recommended Requirement:
- CPU: Hexadeca-core (16 cores) processor
- Memory: 64GB RAM
- Disk Space: 1TB+ (SSD is suggested for better performance)
- OS: Ubuntu 22.04.X LTS (Linux Distro with Ubuntu 22.04.X LTS with base it's okay, but not recommended.)
- GPU*: Intergretate Graphics (iGPU)/APU processor (dGPU/eGPU is very optional and have no benerfic for this project)

*Alacritty or similar is mandatory for the Hardware Acceleration

### Packages Server Minimun Requirement:
- CPU: Dual-core (2 cores) processor (or higher recommended for better performance)
- Memory: 16GB RAM (or higher recommended for better performance)
- Disk Space: 250GB (SSD is suggested for better performance)

### Packages Server Recommended Requirement:
- CPU: Quad-core (4 cores) processor (or higher recommended for better performance)
- Memory: 16GB RAM (or higher recommended for better performance)
- Disk Space: 500GB (SSD is suggested for better performance)

### Raise3D E2 Requirement:
- 16GB-32GB SD CARD SDHC (preferencly 32 GB)
- All necessary tools
- Understand the risk of: lost of wanrandy and no Raise3D support

#### Installation:
```
sudo apt update
sudo apt install git curl
```

```
git config --global user.name "Your Name"
git config --global user.email you@example.com
```

```
mkdir ~/bin
curl http://commondatastorage.googleapis.com/git-repo-downloads/repo  > ~/bin/repo
chmod a+x ~/bin/repo
PATH=${PATH}:~/bin
```

```
mkdir ./RSB-4411_Yocto_Klipper
cd ./RSB-4411_Yocto_Klipper
repo init -u https://github.com/ADVANTECH-Corp/adv-arm-yocto-bsp.git -b imx-linux-mickledore -m imx6LBVD0029.xml
repo sync
```

```
cd ..
git clone https://github.com/AstromanGaming/RSB-4411_Yocto_Klipper.git
cd ./RSB-4411_Yocto_Klipper
```

#### For the main build:
```
./imx6LBVD0029.sh
```

#### Sources:
- https://github.com/ADVANTECH-Corp/adv-arm-yocto-bsp/tree/imx6LBVD0029
- https://ess-wiki.advantech.com.tw/view/IoTGateway/BSP/Linux/iMX6/Yocto_LBVD_User_Guide
