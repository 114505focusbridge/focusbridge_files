from flask import Flask, render_template, request, jsonify
from emotion_model import analyze_sentiment

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/analyze", methods=["POST"])
def analyze():
    text = request.json.get("text", "")
    sentiment_label, message, keywords, topics = analyze_sentiment(text)
    print(f"✅ 收到使用者日記：{text}")


    return jsonify({
        "sentiment": sentiment_label,
        "keywords": keywords,
        "topics": topics,
        "message": message
    })

if __name__ == "__main__":
    app.run(debug=True)