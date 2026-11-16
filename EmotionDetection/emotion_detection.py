"""Emotion detection using the Watson NLP EmotionPredict service."""

import json

import requests

URL = (
    "https://sn-watson-emotion.labs.skills.network/v1/"
    "watson.runtime.nlp.v1/NlpService/EmotionPredict"
)
HEADERS = {"grpc-metadata-mm-model-id": "emotion_aggregated-workflow_lang_en_stock"}
EMOTIONS = ("anger", "disgust", "fear", "joy", "sadness")


def emotion_detector(text_to_analyse):
    """Analyse the emotions in a piece of text.

    Sends the text to the Watson NLP emotion service and returns a dictionary
    with a score for each of anger, disgust, fear, joy and sadness, plus the
    dominant emotion (the one with the highest score).

    If the service answers with status code 400 (for example, for blank
    input), every value in the dictionary is None.
    """
    payload = {"raw_document": {"text": text_to_analyse}}
    response = requests.post(URL, json=payload, headers=HEADERS, timeout=10)

    if response.status_code == 400:
        result = {emotion: None for emotion in EMOTIONS}
        result["dominant_emotion"] = None
        return result

    formatted = json.loads(response.text)
    scores = formatted["emotionPredictions"][0]["emotion"]
    result = {emotion: scores[emotion] for emotion in EMOTIONS}
    result["dominant_emotion"] = max(EMOTIONS, key=lambda emotion: result[emotion])
    return result
