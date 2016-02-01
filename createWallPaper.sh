#!/usr/bin/bash
#joetww@gmail.com

export LC_ALL=en_US.UTF-8
$(which chcp.com) 65001 > /dev/null

dir_new=$( cd $(dirname $0) ; pwd -P )


content_format="\n%-10s : %45s\n"
content_font=$($(which cygpath.exe) -u "C:\Windows\Fonts\msgothic.ttc")
fontsize=16


directory=~/wallpapers/bing/
test \! -d ${directory} && mkdir -p ${directory}

#Base Bing URL
bing="www.bing.com"

#What day to start from. 0 is the current day,1 the previous day, etc...
day="&idx=0"

#Number of images to get
#May change this script later to get more images and rotate between them
number="&n=1"

#Set market, other options are:
#"&mkt=zh-CN"
#"&mkt=ja-JP"
#"&mkt=en-AU"
#"&mkt=en-UK"
#"&mkt=de-DE"
#"&mkt=en-NZ"
#"&mkt=en-CA"
market="&mkt=en-US"

xmlURL=${bing}"/HPImageArchive.aspx?format=xml"${day}${number}${market}

#Set resolution, other options are:
#"_1024x768"
#"_1280x720"
#"_1366x768"
#"_1920x1200"
resolution="_1920x1080"

#The file extension for the Bing pic
extension=".jpg"

#The URL for the desired pic resolution
pic_desired=${bing}$(echo $($(which wget) -q -O - $xmlURL) | $(which grep) -oP "<urlBase>(.*)</urlBase>" | $(which cut) -d ">" -f 2 | $(which cut) -d "<" -f 1)${resolution}${extension}

#Form the URL for the default pic resolution
pic_default=${bing}$(echo $($(which wget) -q -O - $xmlURL) | $(which grep) -oP "<url>(.*)</url>" | $(which cut) -d ">" -f 2 | $(which cut) -d "<" -f 1)

if $(which wget) -q --spider "${pic_desired}"
then
    pic_name=${pic_desired##*/}
    $(which wget) -q -O ${directory}${pic_name} ${pic_desired}
else
    pic_name=${pic_default##*/}
    $(which wget) -q -O ${directory}${pic_name} ${pic_default}
fi


width=$($(which wmic) desktopmonitor get screenwidth | $(which grep) -vE '[a-z]+' | $(which tr) '\r\n' ' ')
height=$($(which wmic) desktopmonitor get screenheight | $(which grep) -vE '[a-z]+' | $(which tr) '\r\n' ' ')
resolution=""
len=${#width[@]}
delim=" "
for ((i=0;i<len;i++)); do
	resolution="${resolution}${delim}${width[i]}x${height[i]}"
done
resolution=$($(which echo) $resolution | $(which sed) "s/$delim//")
x=$($(which echo) ${resolution} | $(which awk) 'BEGIN{FS="x"}{print $1}')    #1920
content=""

content=${content}$(date)
eval $($(which wmic) cpu get LoadPercentage /format:list | $(which tr) '\r\n' ' ')
###content=$($(which screenfetch) -n -N -t -p | $(which iconv) -f big5 -t utf-8)
content=${content}$($(which printf) "${content_format}" "IP" "$($(which ipconfig) | $(which iconv) -f big5 -t utf-8 | $(which grep) -A 5 "區域連線:" | $(which grep) -P 'IPv4 Address.*(\d{1,3}\.){3}\d{1,3}' | $(which awk) '{print $NF}')")
content=${content}$($(which printf) "${content_format}" "CPU" "$($(which wmic) cpu get name | $(which tr) '\r\n' ' ' | $(which sed) -e 's/^Name\s\+\(.*\)\s\+$/\1/' -e 's/\s\+$//')")
content=${content}$($(which printf) "${content_format}" "RESOLUTION" ${resolution})

content=${content}$($(which printf) "${content_format}" "CPULOADING" ${LoadPercentage})
##echo -e "${content}"
echo -e "${content}" | $(which convert) -border 10 -bordercolor white -background white -font ${content_font} -pointsize ${fontsize} -fill black label:@- "${dir_new}/label_centered.jpg"
content_width=$($(which identify) "${dir_new}/label_centered.jpg" | $(which awk) 'BEGIN{FS="[ |x]"}{print $3}')
content_heigh=$($(which identify) "${dir_new}/label_centered.jpg" | $(which awk) 'BEGIN{FS="[ |x]"}{print $4}')
content_x=$(expr ${x} - ${content_width} - 350)
##$(which convert) -size ${resolution} xc:DeepSkyBlue3 "${dir_new}/base1.jpg"
##$(which convert) "${dir_new}/base.jpg" -font ${content_font} -pointsize ${fontsize} -fill white -draw "text ${content_x}, 100 '$(echo -e "${content}")'" "${dir_new}/ip.jpg"
$(which convert) -size ${resolution} xc:transparent -gravity NorthEast \
	 -fill SlateBlue1 -draw "image over 100,150 0,0 '${dir_new}/label_centered.jpg'" "${dir_new}/base2.png"
$(which composite) -dissolve 70% -quality 100 "${dir_new}/base2.png" "${directory}${pic_name}" "${dir_new}/ip.jpg"

cat << "EOD" > "${dir_new}/Set-Wallpaper.ps1"
#0: Tile 1: Center 2: Stretch 3: No Change
param (
	[string]$wallpaper_path = '.'
)
Add-Type @"
using System;
using System.Runtime.InteropServices;
using Microsoft.Win32;
namespace Wallpaper
{
   public enum Style : int
   {
       Tile, Center, Stretch, NoChange
   }
   public class Setter {
      public const int SetDesktopWallpaper = 20;
      public const int UpdateIniFile = 0x01;
      public const int SendWinIniChange = 0x02;
      [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
      private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
      public static void SetWallpaper ( string path, Wallpaper.Style style ) {
         SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
         RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
         switch( style )
         {
            case Style.Stretch :
               key.SetValue(@"WallpaperStyle", "2") ; 
               key.SetValue(@"TileWallpaper", "0") ;
               break;
            case Style.Center :
               key.SetValue(@"WallpaperStyle", "1") ; 
               key.SetValue(@"TileWallpaper", "0") ; 
               break;
            case Style.Tile :
               key.SetValue(@"WallpaperStyle", "1") ; 
               key.SetValue(@"TileWallpaper", "1") ;
               break;
            case Style.NoChange :
               break;
         }
         key.Close();
      }
   }
}
"@



#Write-Host $wallpaper_path
[Wallpaper.Setter]::SetWallpaper( $wallpaper_path, 2 )
[Environment]::Exit(1)
EOD

$(which vim) +':w ++ff=dos' +':q' "${dir_new}/Set-Wallpaper.ps1"
if [ -f "$(dirname $0)/Set-Wallpaper.ps1" ]
then
	##$(which powershell.exe) -File "$(dirname $0)/Set-Wallpaper.ps1"  -wallpaper_path "$($(which cygpath) -w ${dir_new}/ip.jpg)"
	$(which powershell.exe) -File "$($(which cygpath) -w ${dir_new}/Set-Wallpaper.ps1)"  -wallpaper_path "$($(which cygpath) -w ${dir_new}/ip.jpg)"
fi
