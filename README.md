# SwiftCamera
This is a demo project for access the camera in iOS, and encoding the captured stream data to h264/uLaw.

The video streaming data will save to "h264.data" in document directory of your app sandbox. To play it, warp the file by ffmpeg command: ffmpeg -i "h264.data" -c:v copy -f mp4 "myOutputFile.mp4"

The audio streaming data will save to "uLaw.data" in document directory of your app sandbox.

- To acquire iOS camera resource
- Encoding the video stream to h264 format
- Encoding the audio stream to uLaw format

TODO:
- Resampling the audio stream to 8khz
- Combine the Video and Audio stream as a single media file
- Some UI elements
