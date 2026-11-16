#!/usr/bin/env bash
# lab_capture.sh
# Run this INSIDE the Skills Network lab (the real Watson service only works
# there), from the project root:
#     cd /home/project/final_project && bash lab_capture.sh
# Each graded terminal step is run for real and its output is saved in
# terminal_outputs/ under the file name the assignment asks for.
set -u

if [ -f emotion_detection.py ]; then
  echo "Remove or rename ./emotion_detection.py first (this script manages it)."
  exit 1
fi
if [ ! -d EmotionDetection ]; then
  echo "Run this from the project root (the folder that contains EmotionDetection/)."
  exit 1
fi

OUT=terminal_outputs
mkdir -p "$OUT"
STAGES=$(mktemp -d)
trap 'rm -f emotion_detection.py; rm -rf "$STAGES"' EXIT

command -v pylint >/dev/null 2>&1 || pip install -q pylint

# Print a prompt-style line (shows the project path), then the real command runs.
step() { printf '%s$ %s\n' "$(pwd)" "$*"; }
run_py() {
  printf '%s$ python3 -c "%s"\n' "$(pwd)" "$1"
  python3 -c "$1"
}

# Earlier-stage versions of emotion_detection.py (needed for 2b and 3b).
cat > "$STAGES/stage1.py" <<'STAGE1'
import requests


def emotion_detector(text_to_analyse):
    url = 'https://sn-watson-emotion.labs.skills.network/v1/watson.runtime.nlp.v1/NlpService/EmotionPredict'
    headers = {"grpc-metadata-mm-model-id": "emotion_aggregated-workflow_lang_en_stock"}
    myobj = {"raw_document": {"text": text_to_analyse}}
    response = requests.post(url, json=myobj, headers=headers)
    return response.text
STAGE1
cat > "$STAGES/stage2.py" <<'STAGE2'
import json

import requests


def emotion_detector(text_to_analyse):
    url = 'https://sn-watson-emotion.labs.skills.network/v1/watson.runtime.nlp.v1/NlpService/EmotionPredict'
    headers = {"grpc-metadata-mm-model-id": "emotion_aggregated-workflow_lang_en_stock"}
    myobj = {"raw_document": {"text": text_to_analyse}}
    response = requests.post(url, json=myobj, headers=headers)

    # Convert the response text into a dictionary and pull out the emotion scores
    formatted_response = json.loads(response.text)
    emotions = formatted_response['emotionPredictions'][0]['emotion']

    anger_score = emotions['anger']
    disgust_score = emotions['disgust']
    fear_score = emotions['fear']
    joy_score = emotions['joy']
    sadness_score = emotions['sadness']

    # The dominant emotion is the one with the highest score
    scores = {
        'anger': anger_score,
        'disgust': disgust_score,
        'fear': fear_score,
        'joy': joy_score,
        'sadness': sadness_score,
    }
    dominant_emotion = max(scores, key=scores.get)

    return {
        'anger': anger_score,
        'disgust': disgust_score,
        'fear': fear_score,
        'joy': joy_score,
        'sadness': sadness_score,
        'dominant_emotion': dominant_emotion,
    }
STAGE2

# --- 2b: first version of the application (raw Watson response) + unit tests
cp "$STAGES/stage1.py" emotion_detection.py
{
  run_py "from emotion_detection import emotion_detector; print(emotion_detector('I am really mad about this'))"
  rm -f emotion_detection.py
  step "python3 test_emotion_detection.py"
  python3 test_emotion_detection.py
} 2>&1 | tee "$OUT/2b_application_creation.txt"

# --- 3b: formatted output
cp "$STAGES/stage2.py" emotion_detection.py
{
  run_py "from emotion_detection import emotion_detector; print(emotion_detector('I love my life'))"
} 2>&1 | tee "$OUT/3b_formatted_output_test.txt"
rm -f emotion_detection.py

# --- 4b: packaging test
{
  run_py "from EmotionDetection.emotion_detection import emotion_detector; print(emotion_detector('I am very angry'))"
} 2>&1 | tee "$OUT/4b_packaging_test.txt"

# --- 5b: unit tests
{
  step "python3 test_emotion_detection.py -v"
  python3 test_emotion_detection.py -v
} 2>&1 | tee "$OUT/5b_unit_testing_result.txt"

# --- 8b: static code analysis
{
  step "pylint server.py"
  pylint server.py
} 2>&1 | tee "$OUT/8b_static_code_analysis.txt"

echo
echo "================ DONE ================"
ls -1 "$OUT"
BAD=$(grep -lE "Traceback|FAILED" "$OUT"/*.txt 2>/dev/null || true)
if [ -n "$BAD" ]; then
  echo
  echo "WARNING: errors found in these files. Do NOT submit them, send them to Claude:"
  echo "$BAD"
else
  echo "No tracebacks or failures detected."
fi
