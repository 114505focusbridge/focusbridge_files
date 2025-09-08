from dotenv import load_dotenv

load_dotenv()  # 這行會讀取 .env 檔案並把內容塞到 os.environ 裡
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
    "開心", "快樂", "滿足", "期待", "興奮", "爽爆", "開薰", "超 chill", "好幸福", "有成就感","很喜歡", "很開心", "很滿", "開心", 
    "快樂", "興奮", "愉快", "喜悅", "雀躍", "樂觀", "喜樂", "狂喜", "歡喜", "歡暢",
    "興高采烈", "賞心悅目", "心花怒放", "笑逐顏開", "賞心樂事", "欣喜若狂", "悅目娛心", "歡天喜地", "高興", "喜悅", "喜樂", "高興", "快活",
    "快樂的不得了","不錯", "蠻好", "爽快", "舒服", "舒暢", "放心", "釋放", "感恩", "感激", "感謝", "崇拜", "歡愉",
    "滿足", "滿意", "陶醉", "誇讚", "幸福", "快樂有趣", "心醉神迷", "得意洋洋", "很得意", "很自豪", "有信心", "有把握", "很享受",
    "有能力", "很安慰", "很光榮", "有盼望", "有成就感", "有安全感", "有感興趣", "被稱讚", "被尊重", "被激勵", "被重視", "被吸引",
    "被認同", "被瞭解", "被欣賞", "被鼓舞", "被信任", "被接納", "被呵護", "被包容", "被肯定", "被關心", "被需要", "被體諒",
    "被愛", "親密", "甜蜜", "貼心", "溫馨", "溫暖", "安慰", "親密感", "觸電感", "歸屬感", "受感動", "細心體貼", "平安", "自由",
    "自在", "輕鬆", "寧靜", "怡然", "自得", "放鬆", "平靜", "安穩", "柔和", "心靈安詳", "溫和", "振奮", "驚喜", "痛快", "過癮",
    "興致勃勃", "仁慈", "體諒", "信心", "體貼", "慷慨", "有同情心", "有活力", "生氣勃勃", "有精力", "開朗", "開闊", "有希望",
    "有期待", "意想不到", "不可思議", "美夢成真", "熱血沸騰","在一起", "聊天", "放鬆", "開心", "摯友"

]
NEGATIVE_WORDS = [
    "悲傷", "懊惱", "沮喪", "失望", "灰心", "心痛", "難過", "可憐", "委屈", "氣餒",
    "想哭", "心碎", "消沈", "不爽", "洩氣", "傷心", "哀傷", "愛慮", "沈重", "可怕",
    "後悔", "無聊", "彆扭", "苦惱", "痛苦", "辛苦", "很苦", "很累", "冷淡", "悶間的",
    "不高興", "不快樂", "不舒服", "壓迫感", "受傷害", "沒盼望", "悲痛", "感到難過", "感到可惜", "悔恨",
    "憂鬱", "喪氣", "淒慘", "絕望", "自暴自棄", "虛空", "孤單", "寂寞", "苦悶", "迷惘",
    "茫然", "疑惑", "無奈", "無助", "麻木", "可惜", "失落", "鬱悶", "被遺棄", "無力感",
    "無依無靠", "失魂落魄", "生氣", "憤怒", "怨恨", "被騙", "氣憤", "厭惡", "嫉妒", "不滿",
    "受挫", "憤慨", "煩躁", "惱怒", "懷恨", "狂怒", "討厭", "無理", "苦毒", "沒耐心",
    "有惡意", "被誤會", "被壓抑", "被勉強", "被激怒", "被控制", "被陷害", "被利用", "被出賣", "被左右",
    "莫名其妙", "不懷好意", "怒氣沖沖", "令人討厭", "羞恥", "羞愧", "自卑", "怕羞", "慚愧", "內疚",
    "很糗", "丟臉", "想逃", "挫折感", "被冤枉", "冒犯", "驚恐", "被批評", "被拒絕", "被責備",
    "被嘲笑", "被輕視", "窘迫不安", "被羞辱", "沒面子", "沒信心", "被忽視", "被忽略", "不好意思", "不被重視",
    "不被尊重", "焦慮", "掙扎", "矛盾", "緊張", "驚慌", "慌張", "恐懼", "急", "害怕",
    "懼怕", "拒絕", "不安", "擔心", "擔憂", "混亂", "糟糕", "窒息感", "怪怪的", "被驚嚇",
    "膽小", "被拋棄", "不安全", "被虐待", "失去方向", "不知所措", "無所適從", "心煩意亂", "亂七八糟", "亂成一團",
    "無可奈何", "無能為力", "心神不安", "憎惡", "輕蔑", "不喜歡", "令人作嘔", "驚訝", "驚奇", "吃驚", "昏倒", "仇富"
    "殺人", "自殺", "爆氣", 
]

# 事件詞庫，分成正面跟負面（甚至可以加中立）
POSITIVE_EVENTS = [
    "婚禮", "成果發表會", "音樂會", "慶典", "畢業典禮", "升職", "約會", "旅行"
]

NEGATIVE_EVENTS = [
    "葬禮", "病痛", "失業", "分手", "考試失敗", "受傷", "車禍", "去世", "走了", "離開人世",
]

NEUTRAL_EVENTS = [
    "會議", "拜訪", "出差", "通勤"
]


# 主題分類關鍵詞
AWARENESS_WORDS = ["注意到", "覺得", "發現", "意識到", "醒悟", "體會", "感覺到", "理解", "深知", "了解", "深知" ]
CONTROL_WORDS = ["忍住", "壓下", "控制", "冷靜", "不發火", "壓抑", "抑鬱", "吞下怒火",] 
MANAGEMENT_WORDS = ["安排", "規劃", "處理", "面對", "調整", "應付", "解決", "完成", "結束"]

# Gemini API 設定（需設定環境變數 GEMINI_API_KEY）
# 若你希望使用快速版 Flash（回應速度較快）
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
print("DEBUG: Gemini API key =", GEMINI_API_KEY)


def generate_gemini_message(summary: str):
    if not GEMINI_API_KEY:
        print("⚠️ GEMINI_API_KEY 未設定")
        return None
    headers = {
        "Content-Type": "application/json",
        "X-goog-api-key": GEMINI_API_KEY
    }
    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "text": f"你是一位善於傾聽、理解與鼓勵的人，句尾的方式寫一段 1～2 句話的話語，除了溫暖安慰，分析他今天可能經歷了哪些情緒（如焦慮、疲憊、難過、期待、快樂等），並以貼近人心、真誠自然的語氣回應他，但從使用者的角度出發就好，不要自己帶入過多的猜測，也不要反問句，讓他感受到被理解和支持。請注意不要使用罐頭式的空泛鼓勵語：{summary}"
                    }
                ]
            }
        ]
    }
    try:
        response = requests.post(GEMINI_API_URL, headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        print("Gemini API 回傳:", result)
        return result["candidates"][0]["content"]["parts"][0]["text"]
    except Exception as e:
        print("Gemini API 呼叫失敗:", e)
        if hasattr(e, 'response') and e.response is not None:
            print("回應內容:", e.response.text)
        return None

def extract_keywords_from_text(text):
    return [kw for kw in POSITIVE_WORDS + NEGATIVE_WORDS if kw in text]


def analyze_sentiment(text: str):
    try:
        # Step 1: 情緒分類
        inputs = tokenizer(text, return_tensors="pt", truncation=True, padding=True)
        with torch.no_grad():
            outputs = model(**inputs)
            logits = outputs.logits
            probs = torch.softmax(logits, dim=1)
            label_id = torch.argmax(probs, dim=1).item()
            label = label_map[label_id]

        # Step 2: 斷詞並找出情緒詞
        # 中文斷詞（保留給主題分析）
        words = list(jieba.cut(text))

        pos_count = sum(1 for w in words if w in POSITIVE_WORDS)
        neg_count = sum(1 for w in words if w in NEGATIVE_WORDS)

        if pos_count > neg_count:
            label = "positive"
        elif neg_count > pos_count:
            label = "negative"
        else:
            label = "neutral"
        
        


# ✅ 改成全文搜尋情緒詞（避免斷詞抓不到）
        emotion_keywords = extract_keywords_from_text(text)


        # Step 3: 探測主題
        topics = []
        if any(w in words for w in AWARENESS_WORDS):
            topics.append("自我覺察")
        if any(w in words for w in CONTROL_WORDS):
            topics.append("自我控制")
        if any(w in words for w in MANAGEMENT_WORDS):
            topics.append("自我管理")

        # Step 4: 利用關鍵詞構造摘要（不含原文）
        summary_parts = [f"偵測到的情緒傾向：{label}"]
        if emotion_keywords:
            summary_parts.append("出現的情緒詞：" + ", ".join(set(emotion_keywords)))
        if topics:
            summary_parts.append("可能的主題：" + ", ".join(topics))

        summary = "；".join(summary_parts)

        # Step 5: 送給 Gemini
        message = generate_gemini_message(summary)
        if not message:
            message = default_message_map.get(label, "保持勇氣，繼續加油！")

        return label, message, emotion_keywords, topics

    except Exception as e:
        print("❌ 分析失敗:", e)
        return "neutral", default_message_map["neutral"], [], []
