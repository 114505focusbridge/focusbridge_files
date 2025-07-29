from transformers import AutoTokenizer, AutoModelForSequenceClassification
import torch
import jieba
import requests
import os

# 載入情緒分類模型
MODEL_NAME = "IDEA-CCNL/Erlangshen-RoBERTa-110M-Sentiment"
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
model = AutoModelForSequenceClassification.from_pretrained(MODEL_NAME)
model.eval()

# 標籤對應與預設鼓勵語句
label_map = {0: "negative", 1: "neutral", 2: "positive"}
default_message_map = {
    "positive": "你今天的心情聽起來很棒，請繼續保持哦！",
    "neutral": "無論心情如何，紀錄的每一步都是自我照顧的一部分。",
    "negative": "今天可能有點辛苦，但你願意寫下來，就已經很了不起了。"
}

# 情緒關鍵詞詞庫（擴充含現代用語）
POSITIVE_WORDS = [
    "開心", "快樂", "滿足", "期待", "興奮",
    "爽爆", "開薰", "超 chill", "好幸福", "有成就感"
]
NEGATIVE_WORDS = [
    "悲傷", "焦慮", "憤怒", "煩躁", "崩潰", "無力", "痛苦", "累", "不想動",
    "爆炸", "超煩", "好厭世", "不想社交", "爛透了", "心累", "很悶"
]

# 主題分類關鍵詞
AWARENESS_WORDS = ["注意到", "覺得", "發現", "意識到", "醒悟", "體會"]
CONTROL_WORDS = ["忍住", "壓下", "控制", "冷靜", "不發火", "壓抑"]
MANAGEMENT_WORDS = ["安排", "規劃", "處理", "面對", "調整", "應付"]

# Gemini API 設定（需設定環境變數 GEMINI_API_KEY）
# 若你希望使用快速版 Flash（回應速度較快）
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

def generate_gemini_message(summary: str):
    if not GEMINI_API_KEY:
        return None  # 沒有設定金鑰則不呼叫 API
    headers = {
        "Content-Type": "application/json",
        "X-goog-api-key": GEMINI_API_KEY
    }
    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "text": f"請根據下方情緒摘要，模擬一位理解情緒的心理師，寫一段 1～2 句話的話語，除了溫暖安慰，還請提供一個可以立刻執行的小行動建議（例如：做一次深呼吸、寫下此刻的感覺、喝口水冷靜一下等）。語氣請溫暖但不浮誇，重點是讓人感受到被理解與支持，並且知道自己下一步可以怎麼做。  請避免空泛鼓勵（例如「你要加油」），而是真誠、實用的心理支持話語。情緒摘要：{summary}"
                    }
                ]
            }
        ]
    }
    try:
        response = requests.post(GEMINI_API_URL, headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        return result["candidates"][0]["content"]["parts"][0]["text"]
    except Exception as e:
        print("Gemini API Error:", e)
        return None

def analyze_sentiment(text: str):
    # 模型分類
    inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)
    with torch.no_grad():
        outputs = model(**inputs)
        logits = outputs.logits
        probs = torch.softmax(logits, dim=1)
        label_id = torch.argmax(probs, dim=1).item()
        label = label_map[label_id]

    # 中文斷詞
    words = list(jieba.cut(text))

    # 情緒詞彙擷取
    keywords = [w for w in words if w in POSITIVE_WORDS + NEGATIVE_WORDS]

    # 主題分類
    topics = []
    if any(w in words for w in AWARENESS_WORDS):
        topics.append("自我覺察")
    if any(w in words for w in CONTROL_WORDS):
        topics.append("自我控制")
    if any(w in words for w in MANAGEMENT_WORDS):
        topics.append("自我管理")

    # 建立摘要供 Gemini 使用（不包含日記全文）
    summary_parts = [f"情緒為 {label}"]
    if keywords:
        summary_parts.append("出現詞彙：" + ", ".join(keywords))
    if topics:
        summary_parts.append("主題分類：" + ", ".join(topics))
    summary_text = "；".join(summary_parts)

    # 呼叫 Gemini 生成建議
    message = generate_gemini_message(summary_text) or default_message_map[label]

    return label, message, keywords, topics
