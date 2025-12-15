# YoctianOS for RSB-4411

## Warning: It's not finish and it's WIP!

### PC Minimun Requirement:
- CPU: Quad-core (4 cores) processor (or higher very recommended for better compile performance)
- Memory: 16GB RAM (or higher recommended for better task performance)
- Disk Space: 500GB-1TB (SSD is suggested for better performance)
- OS: Ubuntu 22.04.X LTS (Linux Distro with Ubuntu 22.04.X LTS with base it's okay)
- GPU*: N/A (if you're don't use GUI)

### PC Recommended Requirement:
- CPU: Hexadeca-core (16 cores) processor
- Memory: 64GB RAM
- Disk Space: 1TB+ (SSD is suggested for better performance)
- OS: Ubuntu 22.04.X LTS (Linux Distro with Ubuntu 22.04.X LTS with base it's okay)
- GPU*: Intergretate Graphics (iGPU)/APU processor (dGPU/eGPU is very optional and have no benefic for this project)

*Alacritty or similar is mandatory for the Hardware Acceleration

### RSB-4411 Requirement:
- 16GB-32GB SD CARD SDHC (preferencly 32 GB)
- All necessary tools

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
mkdir ./YoctianOS-Distro
cd ./YoctianOS-Distro
repo init -u https://github.com/ADVANTECH-Corp/adv-arm-yocto-bsp.git -b imx-linux-mickledore -m imx6LBVD0029.xml
repo sync
```

```
cd ..
git clone https://github.com/YoctianOS/YoctianOS-Distro.git
cd ./YoctianOS-Distro/script/imx6LBVD0029
```

#### For the main build:
```
./main.sh
bitbake imx-image-core
```

#### Sources:
- https://github.com/ADVANTECH-Corp/adv-arm-yocto-bsp/tree/imx6LBVD0029
- https://ess-wiki.advantech.com.tw/view/IoTGateway/BSP/Linux/iMX6/Yocto_LBVD_User_Guide
