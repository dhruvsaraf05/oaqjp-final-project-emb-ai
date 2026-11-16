# Final Project

Emotion Detector: a small Flask web application that detects emotions in text using the Watson NLP
library. It scores a statement for anger, disgust, fear, joy and sadness and
reports the dominant emotion.

## Project layout

```
EmotionDetection/
    __init__.py            # package entry point
    emotion_detection.py   # emotion_detector() calling Watson NLP
templates/index.html       # web UI
static/mywebscript.js      # front-end request logic
server.py                  # Flask app (port 5000)
test_emotion_detection.py  # unit tests
```

## Run it

```bash
pip install flask requests
python3 server.py
```

Then open http://localhost:5000.

## Test and lint

```bash
python3 -m unittest test_emotion_detection -v
pylint server.py
```

## Error handling

Blank input makes the Watson service answer with status code 400. The
application then returns `None` for every field and the web page shows
"Invalid text! Please try again!".
