# backend/api/utils/emotion_models.py
from __future__ import annotations
from typing import List, Tuple, Dict
import os
import re
import jieba
import torch
import requests
from transformers import AutoTokenizer, AutoModelForSequenceClassification
from dotenv import load_dotenv

# ───────────────────────────────────────────────────────────────
# 0) 設定與載入
# ───────────────────────────────────────────────────────────────
load_dotenv()

MODEL_NAME = "IDEA-CCNL/Erlangshen-RoBERTa-110M-Sentiment"

# 權重：模型 vs 詞典（可微調）
W_MODEL = 0.6
W_LEX = 0.4
# 中立門檻（-T ~ +T 是 neutral）
T_NEU = 0.15

# 最大 token 長度（分段推論就不用很大）
MAX_LEN = 256
# 長文每段字數（非 token，是字/字元粗估）
CHUNK_CHAR = 220

# 安全載入模型（載入失敗不阻斷整體功能）
try:
    tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
    model = AutoModelForSequenceClassification.from_pretrained(MODEL_NAME)
    model.eval()
except Exception as e:
    print(f"❌ 模型載入失敗：{e}")
    tokenizer = None
    model = None

# ───────────────────────────────────────────────────────────────
# 1) 詞典、否定詞、強度詞、emoji、事件詞
# ───────────────────────────────────────────────────────────────
POSITIVE_WORDS = set([
    "開心","快樂","滿足","期待","興奮","幸福","放鬆","踏實","安心","順利",
    "爽","超爽","chill","開薰","有成就感","舒服","放心","雀躍","很棒","太好了",
    "愉快","喜悅","高興","快活","振奮","驚喜","過癮","熱血","喜樂","欣喜若狂",
    "很喜歡","很開心","很滿","自由","自在","輕鬆","寧靜","安穩","被肯定","被欣賞",
])

NEGATIVE_WORDS = set([
    "悲傷","焦慮","憤怒","煩躁","崩潰","無力","痛苦","累","厭世","爆炸","很煩",
    "失望","沮喪","難過","低落","不爽","爛透","心累","很悶","壓力山大","喪氣",
    "可惜","失落","憂鬱","恐懼","害怕","緊張","慌張","不安","擔心","混亂","糟糕",
    "被忽視","被責備","被嘲笑","羞愧","丟臉","無助","無奈","無能為力","抓狂",
])

# 事件詞（不是強情緒詞，但給「方向性加分/扣分」，例如：動物園/生日偏正向）
POSITIVE_EVENTS = set([
    "動物園","生日","約會","旅行","旅遊","出遊","音樂會","演唱會","慶生","畢業典禮","升職","放假",
])

NEGATIVE_EVENTS = set([
    "葬禮","生病","失業","分手","吵架","被罵","考試失敗","車禍","過世","去世",
])

# 否定詞（翻轉極性，作用範圍：前一個 token）
NEGATIONS = set(["不","沒","沒有","別","無","未","不太","不大","不怎麼"])
# 強度詞（加權）
STRONG_INTENSIFIERS = set(["超","超級","非常","爆","爆炸","巨","超級無敵","超級爆"])
WEAK_INTENSIFIERS = set(["很","挺","蠻","有點","稍微","有些"])

# 常見 emoji 的極性
EMOJI_POLARITY = {
    "😀": 2, "😄": 2, "😁": 2, "🤣": 2, "😂": 2, "😊": 1, "🙂": 1, "😍": 2, "👍": 1, "✨": 1,
    "😐": 0, "🤔": 0, "😶": 0,
    "😕": -1, "😞": -2, "😟": -2, "😢": -2, "😭": -3, "😡": -3, "🤬": -3, "👎": -1, "💔": -2,
}

# 主題偵測關鍵詞
AWARENESS_WORDS = ["注意到","覺得","發現","意識到","體會","察覺"]
CONTROL_WORDS   = ["忍住","壓下","控制","冷靜","不發火","壓抑","克制"]
MANAGEMENT_WORDS= ["安排","規劃","處理","面對","調整","應對","應付","解決","完成"]

# 預設訊息（不用呼吸口令）
DEFAULT_MSG = {
    "positive": "聽起來你的心情很好，保持這份能量去面對接下來的事情吧！",
    "neutral" : "你把當下的狀態記錄下來了，這本身就是很好的練習。",
    "negative": "讀起來今天有點不容易，願你被好好看見，也能對自己溫柔一些。",
}

# Gemini（可有可無；沒有 API key 就用 DEFAULT_MSG）
GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# ───────────────────────────────────────────────────────────────
# 2) 工具：長文分段 / Jieba + emoji token 化
# ───────────────────────────────────────────────────────────────
_EMOJI_RE = re.compile(
    "["               # 這個正則能抓大部分 emoji（不是完美，但足以）
    "\U0001F300-\U0001F6FF"
    "\U0001F900-\U0001F9FF"
    "\U0001F1E6-\U0001F1FF"
    "\u2600-\u26FF"
    "\u2700-\u27BF"
    "]+")

def _split_chunks_by_char(s: str, chunk_len: int = CHUNK_CHAR) -> List[str]:
    s = s.strip()
    if not s:
        return [s]
    return [s[i:i+chunk_len] for i in range(0, len(s), chunk_len)]

def _tokenize_with_emoji(text: str) -> List[str]:
    # 先把 emoji 用空白分開，再丟 jieba
    text = _EMOJI_RE.sub(lambda m: f" {m.group(0)} ", text)
    # 也把標點適度切開（簡單處理）
    text = re.sub(r"([!?！？。，,.…~])", r" \1 ", text)
    tokens = list(jieba.cut(text))
    # 移除空白 token
    return [t.strip() for t in tokens if t.strip()]

# ───────────────────────────────────────────────────────────────
# 3) 詞典分數：否定/強度/emoji/驚嘆號
# ───────────────────────────────────────────────────────────────
def _lexicon_score(tokens: List[str]) -> float:
    score = 0.0
    hits = 0

    for i, w in enumerate(tokens):
        base = 0.0
        if w in POSITIVE_WORDS:
            base = 1.0
        elif w in NEGATIVE_WORDS:
            base = -1.0
        elif w in EMOJI_POLARITY:
            base = float(EMOJI_POLARITY[w])
        else:
            continue

        # 修飾詞：看前一個 token
        modifier = 1.0
        prev = tokens[i-1] if i > 0 else ""
        if prev in NEGATIONS:
            base *= -1.0
        if prev in STRONG_INTENSIFIERS:
            modifier *= 1.5
        elif prev in WEAK_INTENSIFIERS:
            modifier *= 1.2

        score += base * modifier
        hits += 1

    # 驚嘆號強度（粗略 0.1/個，最多加到 0.3）
    exclam = sum(1 for t in tokens if t in ["!","！","!!!","！！"])
    score += min(0.3, exclam * 0.1)

    if hits == 0:
        return 0.0
    # 正規化到 [-1, 1]
    norm = score / (hits * 1.5)
    return max(-1.0, min(1.0, norm))

# ───────────────────────────────────────────────────────────────
# 4) 模型分數（2/3 類自動適配），長文取平均
# ───────────────────────────────────────────────────────────────
@torch.no_grad()
def _model_score(text: str) -> Tuple[float, float]:
    """
    回傳：(model_sentiment_score in [-1,1], avg_confidence)
    - 若 num_labels == 3：視為 (neg, neu, pos)，score = p_pos - p_neg
    - 若 num_labels == 2：視為 (neg, pos)，   score = p_pos - p_neg
    - 其他情況：回傳 (0, 0)
    """
    if not tokenizer or not model:
        return 0.0, 0.0

    chunks = _split_chunks_by_char(text, CHUNK_CHAR)
    scores, confs = [], []

    for chunk in chunks:
        if not chunk.strip():
            continue
        try:
            inputs = tokenizer(
                chunk, return_tensors="pt",
                truncation=True, padding=True, max_length=MAX_LEN
            )
            logits = model(**inputs).logits.squeeze(0)  # (num_labels,)
            num_labels = logits.shape[-1]
            probs = torch.softmax(logits, dim=-1)

            if num_labels == 3:
                p_neg, p_neu, p_pos = probs[0].item(), probs[1].item(), probs[2].item()
                score = p_pos - p_neg
                conf = max(p_neg, p_neu, p_pos)
            elif num_labels == 2:
                p_neg, p_pos = probs[0].item(), probs[1].item()
                score = p_pos - p_neg
                conf = max(p_neg, p_pos)
            else:
                continue

            scores.append(float(score))
            confs.append(float(conf))
        except Exception:
            # 某段失敗就略過，不讓整體壞掉
            continue

    if not scores:
        return 0.0, 0.0
    return float(sum(scores)/len(scores)), float(sum(confs)/len(confs))

# ───────────────────────────────────────────────────────────────
# 5) Gemini 訊息（可無）
# ───────────────────────────────────────────────────────────────
def _generate_gemini_message(summary: str):
    if not GEMINI_API_KEY:
        return None
    try:
        headers = {"Content-Type": "application/json", "X-goog-api-key": GEMINI_API_KEY}
        payload = {
            "contents": [{
                "parts": [{
                    "text": (
                        "請以真誠、自然、不誇張的語氣，對下列情緒摘要寫 1～2 句支持訊息。"
                        "避免『做幾次呼吸』等指令、多用同理與鼓勵；正向就提醒保持能量，"
                        "負向就溫柔接住與給一個可行的小步驟（如：寫三件小確幸、傳訊息給信任的人）。"
                        "不要使用反問句，也不要流水帳。\n"
                        f"情緒摘要：{summary}"
                    )
                }]}
            ]}
        r = requests.post(GEMINI_API_URL, headers=headers, json=payload, timeout=12)
        r.raise_for_status()
        data = r.json()
        cands = data.get("candidates") or []
        if not cands:
            return None
        content = (cands[0] or {}).get("content") or {}
        parts = content.get("parts") or []
        if not parts:
            return None
        text = (parts[0] or {}).get("text")
        return text.strip() if isinstance(text, str) and text.strip() else None
    except Exception as e:
        print("❌ Gemini API 錯誤：", e)
        return None

# ───────────────────────────────────────────────────────────────
# 6) 規則式提示語（無 Gemini 時用）
# ───────────────────────────────────────────────────────────────
def _compose_support_message(label: str, keywords: List[str], topics: List[str], extra_hint: str | None) -> str:
    topic_hint = ""
    if topics:
        topic_hint = f"（你也展現了{ '、'.join(topics) }）"

    if label == "positive":
        base = "聽起來你的心情很不錯，保持這份好能量去面對接下來的事情吧！"
        if extra_hint:
            base = f"聽起來你的心情很不錯，{extra_hint}，把這份好能量帶著走吧！"
        return base + ("" if not topic_hint else f"{topic_hint}")
    elif label == "negative":
        base = "讀起來今天不太容易，感謝你寫下來，這已經很勇敢。願你被好好看見，也對自己溫柔一些。"
        return base + ("" if not topic_hint else f"{topic_hint}")
    else:
        base = "你清楚地記錄了此刻，這本身就是很好的練習。"
        if extra_hint:
            base = f"{base} {extra_hint}"
        return base + ("" if not topic_hint else f"{topic_hint}")

# ───────────────────────────────────────────────────────────────
# 7) 主流程：模型+詞典 融合、事件加權、主題標註、訊息產生
# ───────────────────────────────────────────────────────────────
def analyze_sentiment(text: str):
    """
    回傳：(label, message, keywords, topics)
    label ∈ {'positive','neutral','negative'}
    """
    raw = (text or "").strip()
    if not raw:
        return "neutral", DEFAULT_MSG["neutral"], [], []

    tokens = _tokenize_with_emoji(raw)

    # 詞典分數
    lex_s = _lexicon_score(tokens)

    # 模型分數 & 信心
    mdl_s, mdl_conf = _model_score(raw)

    # 權重調整：模型沒載到/信心低 → 提高詞典比重
    if mdl_conf == 0.0:        # 沒模型或完全失敗
        w_model, w_lex = 0.0, 1.0
    elif mdl_conf < 0.55:      # 信心偏低 → 50/50
        w_model, w_lex = 0.5, 0.5
    else:
        w_model, w_lex = W_MODEL, W_LEX

    # 事件加權（弱加分/扣分）
    event_bonus = 0.0
    pos_events_hit = [e for e in POSITIVE_EVENTS if e in raw]
    neg_events_hit = [e for e in NEGATIVE_EVENTS if e in raw]
    if pos_events_hit:
        event_bonus += 0.15   # 例如：提到「動物園/生日」→ 偏正向
    if neg_events_hit:
        event_bonus -= 0.15

    # 特殊口語強化：出現「興奮、期待」等強正向詞
    if any(w in raw for w in ["興奮","超興奮","超期待","超級期待"]):
        event_bonus += 0.15

    # 最終分數
    final_score = w_model * mdl_s + w_lex * lex_s + event_bonus
    final_score = max(-1.0, min(1.0, final_score))

    if final_score > T_NEU:
        label = "positive"
    elif final_score < -T_NEU:
        label = "negative"
    else:
        label = "neutral"

    # 關鍵詞與主題（可再擴充）
    keywords = [w for w in tokens if (w in POSITIVE_WORDS or w in NEGATIVE_WORDS or w in EMOJI_POLARITY)]
    # 把事件也放進 keywords 方便前端展示
    keywords += [e for e in pos_events_hit + neg_events_hit if e not in keywords]

    topics = []
    if any(w in tokens for w in AWARENESS_WORDS):
        topics.append("自我覺察")
    if any(w in tokens for w in CONTROL_WORDS):
        topics.append("自我控制")
    if any(w in tokens for w in MANAGEMENT_WORDS):
        topics.append("自我管理")

    # 摘要給 Gemini（含一些偵測線索）
    summary_parts = [
        f"整體極性分數：{final_score:.2f}（模型 {mdl_s:.2f}×{w_model} + 詞典 {lex_s:.2f}×{w_lex}；事件加權 {event_bonus:+.2f}；信心 {mdl_conf:.2f}）",
        f"判定為：{label}",
    ]
    if keywords:
        ks = [k for k in keywords if k not in ["，","。","!","！"]][:8]  # 只展示前 8 個
        if ks:
            summary_parts.append("線索：" + ", ".join(ks))
    if topics:
        summary_parts.append("主題：" + ", ".join(topics))
    summary_text = "；".join(summary_parts)

    # 先嘗試 Gemini，失敗就用規則訊息（不講呼吸）
    gem = _generate_gemini_message(summary_text)
    if gem and gem.strip():
        message = gem.strip()
    else:
        # 客製一點的小提示（例如偵測到正向事件）
        extra_hint = None
        if pos_events_hit and label == "positive":
            extra_hint = f"看起來你對「{pos_events_hit[0]}」很期待"
        message = _compose_support_message(label, keywords, topics, extra_hint)

    return label, message, keywords, topics
