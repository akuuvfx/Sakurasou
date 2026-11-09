"""Mini serveur yt-dlp pour Sakurasou.
Usage : pip install yt-dlp flask && apt install ffmpeg && python server.py
GET /mp3?url=<lien>  ->  renvoie le MP3
"""
import glob, os, tempfile
from flask import Flask, request, send_file, abort
import yt_dlp

app = Flask(__name__)

@app.get("/mp3")
def mp3():
    url = request.args.get("url")
    if not url:
        abort(400)
    tmp = tempfile.mkdtemp()
    opts = {
        "format": "bestaudio/best",
        "outtmpl": os.path.join(tmp, "%(title)s.%(ext)s"),
        "postprocessors": [{"key": "FFmpegExtractAudio", "preferredcodec": "mp3", "preferredquality": "192"}],
        "quiet": True,
    }
    with yt_dlp.YoutubeDL(opts) as ydl:
        ydl.download([url])
    f = glob.glob(os.path.join(tmp, "*.mp3"))[0]
    return send_file(f, as_attachment=True, download_name=os.path.basename(f))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
