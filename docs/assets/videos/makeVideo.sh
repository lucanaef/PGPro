# remove old files
rm *.png
rm *.mp4
rm *.webm

# get new screenshots
cp ../screenshot/* .

# create video (mp4 format)
ffmpeg -framerate 0.25 -pattern_type glob -i '*.png' -c:v libx264 -pix_fmt yuv420p screenshots.mp4
# get webm file
ffmpeg -i screenshots.mp4 screenshots.webm

# remove screenshots
rm *.png
