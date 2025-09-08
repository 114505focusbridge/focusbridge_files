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
    "感動","感激","感謝","被愛","被需要","被支持","被理解","被接納","被重視","被關心",
    "被尊重","被鼓勵","被讚美","被認同","被照顧","被疼愛","被珍惜","被信任","有趣","幽默",
    "風趣","搞笑","逗趣","讚","讚讚","讚讚讚","棒","棒棒","棒棒棒","太棒了","太讚了","太好了",
    "完美","完美無缺","無敵","無敵了","棒","讚","完美","無敵","超級完美","超級無敵",
    "讚嘆","佩服","敬佩","驕傲","自豪","信心","自信","安全感","力量","勇氣","希望","動力","熱情","幹勁","衝勁",
    "活力","朝氣","精神","靈感","創意","想法","主見","見地","智慧","洞察力","遠見","遠識","遠慮",
])

NEGATIVE_WORDS = set([
    "悲傷","焦慮","憤怒","煩躁","崩潰","無力","痛苦","累","厭世","爆炸","很煩",
    "失望","沮喪","難過","低落","不爽","爛透","心累","很悶","壓力山大","喪氣",
    "可惜","失落","憂鬱","恐懼","害怕","緊張","慌張","不安","擔心","混亂","糟糕",
    "被忽視","被責備","被嘲笑","羞愧","丟臉","無助","無奈","無能為力","抓狂",
    "笨蛋","白痴","智障","混蛋","腦殘","低能","傻眼","發瘋","累死","失落","欺騙",
    "背叛","欺騙","詐騙","暴躁","壓力","抱歉","眼淚","淚","不理我","昏厥","哭泣",
    "哭死","哭慘","崩潰","崩潰了","崩潰中","崩潰ing","崩潰死","崩潰慘","煩死","煩死了","煩死中","煩死ing","煩死慘",
    "氣死","氣死了","氣死中","氣死ing","氣死慘","怒死","怒死了","怒死中","怒死ing","怒死慘","憤死","憤死了","憤死中","憤死ing","憤死慘",
    "悶死","悶死了","悶死中","悶死ing","悶死慘","煩悶","煩悶死","煩悶了","煩悶中","煩悶ing","煩悶慘",
    "心碎","心碎死","心碎了","心碎中","心碎ing","心碎慘","心痛","心痛死","心痛了","心痛中","心痛ing","心痛慘",
    "崩潰","崩潰死","崩潰了","崩潰中","崩潰ing","崩潰慘","失落","難以釋懷", 
])

# 事件詞（不是強情緒詞，但給「方向性加分/扣分」，例如：動物園/生日偏正向）
POSITIVE_EVENTS = set([
    "動物園","生日","約會","旅行","旅遊","出遊","音樂會","演唱會","慶生","畢業典禮",
    "升職","放假","升學","結婚","訂婚","同學會","團聚","野餐","看電影","看展覽",
    "博物館","美術館","逛街","購物","聚餐","派對","家庭聚會","朋友聚會","公司聚會","跨年活動",
    "煙火表演","祭典","運動會","比賽勝利","球賽觀賞","馬拉松完成","領獎","開學典禮","畢業旅行","迎新活動",
    "旅館住宿","溫泉旅行","海邊玩水","登山健行","露營","騎腳踏車","自駕旅行","遊樂園","水上樂園","主題樂園",
    "遊船","郵輪旅行","出國","交換學生","遊學","留學錄取","獎學金","考試通過","駕照考到","語言檢定通過",
    "新家入厝","搬新家","買房子","買車","養寵物","領養動物","寵物生日","寵物康復","家人康復","親人生日",
    "小孩出生","滿月酒","週年紀念日","情人節","聖誕節","新年慶祝","中秋烤肉","端午龍舟","元宵燈會","參加婚禮",
    "朋友結婚","同事升職","家庭旅遊","公司旅遊","出差順利","產品上市","專案成功","創業成功","簽約成功","合作成功",
    "作品發表","演講成功","比賽得獎","考上理想學校","錄取通知","進入理想公司","夢想達成","健康檢查正常","醫生報告良好","久別重逢",
    "升旗典禮","社團活動","志工活動","慈善募款","捐血成功","捐款成功","幫助他人","收到禮物","送出禮物","表白成功",
    "戀愛告白","第一次約會","情侶旅行","蜜月旅行","退休典禮","榮譽獎章","傑出表揚","社區活動","鄉村旅遊","城市觀光",
    "夜市逛街","美食節","咖啡館聚會","早午餐約會","烹飪比賽","烘焙成功","新菜成功","家庭料理聚餐","園藝成果","收成豐收",
    "植樹活動","自然步道","賞櫻","賞楓","賞花","賞雪","賞月","拍攝成功","攝影展覽","美術比賽獲獎",
    "舞蹈演出","音樂比賽得獎","話劇演出成功","電影首映","書籍出版","文章刊登","研究發表","專利通過","實驗成功","科技競賽獲獎",
    "買到夢想中的車","第一次自己租房","升到管理職","工作年終獎金","成功加薪","投資獲利","股票上漲","買到限量商品","收藏完成","夢想清單達成",
    "酒吧聚會","夜店舞會","浪漫燭光晚餐","熱氣球體驗","衝浪體驗","潛水體驗","滑雪旅行","環島旅行","跨國旅遊","豪華飯店住宿",
    "Spa體驗","按摩體驗","美容院護理","健身達成目標","完成馬甲線計畫","馬拉松完賽","健身比賽成功","瑜伽挑戰完成","學會新舞蹈","第一次跳探戈",
    "收到升遷通知","被主管肯定","職場表揚","專案獲獎","公司營收成長","成功演講","論壇受邀","媒體報導","專訪曝光","出版作品",
    "買第一間房子","買第二間房子","海外置產","孩子入學","孩子獲獎","孩子升學成功","家庭合照","三代同堂聚會","父母金婚慶典","祖父母大壽",
    "結婚週年旅行","第二次蜜月","浪漫驚喜","情侶紀念日","同居紀念日","買情侶戒指","交換禮物驚喜","訂製蛋糕","餐廳慶祝","高級晚宴",
    "第一次牽手","第一次接吻","深情擁抱","浪漫依偎","一起過夜","窩在沙發上親熱","熬夜聊天到天亮","親密擁抱後入睡","被驚喜親吻","在雨中接吻",
    "海邊擁抱","看星星時依偎","情侶一起洗澡","親密按摩","床上嬉鬧","被情人摟著睡覺","共度燭光之夜","親密低語","浪漫夜晚","同居後的第一晚"
])



NEGATIVE_EVENTS = set([
    "分手","吵架","被誤會","被罵","被排擠","被背叛","失戀","父母離異","友情破裂","被孤立",
    "生病","重病","受傷","車禍","意外事故","遭遇火災","溺水","遭遇地震","遭遇颱風","遭遇洪水",
    "遭遇土石流","遭遇爆炸","遭遇搶劫","親人過世","寵物過世","葬禮","考試失敗","成績不理想","論文被退","專案失敗",
    "失業","被裁員","面試失敗","升遷失敗","工作壓力過大","被上司責罵","被同事排擠","公司倒閉","被迫離職","經濟困難",
    "破產","負債","偷竊被害","遭詐騙","房租繳不出來","錢包遺失","重要物品遺失","財物損失","手機被偷","電腦壞掉",
    "搬家失敗","租屋糾紛","鄰居糾紛","家庭暴力","霸凌事件","被勒索","法律糾紛","官司敗訴","被逮捕","被停學",
    "被退學","兵役爭議","飛機延誤","航班取消","簽證被拒","旅行意外","丟失護照","交通工具拋錨","搬運受傷","意外跌倒",
    "中毒","食物中毒","藥物副作用","醫療失誤","手術失敗","懷孕流產","婚禮取消","離婚","小孩走失","小孩意外",
    "學校霸凌","被欺騙感情","投資失敗","股票暴跌","合作破裂","計畫中止","比賽失敗","資格被取消","作品被抄襲","作品被否決",
    "演出失敗","表演出錯","債務糾紛","房貸壓力","信用卡欠款","投資虧損","貸款被拒","外遇發現","婚姻冷淡","離婚訴訟",
    "分居","配偶背叛","感情冷淡","親密關係破裂","同居爭執","爭奪財產","親子爭吵","家庭冷戰","朋友背叛","友情破裂",
    "社交拒絕","聚會被排除","職場霸凌","工作糾紛","升職失敗","專案被否決","公司倒閉","被降職","考核失敗","年終獎金取消",
    "公司裁員","失業等待","面試落選","加班過度","健康檢查異常","慢性病惡化","牙痛嚴重","意外受傷","交通違規罰款","駕照被吊銷",
    "車禍受傷","寵物生病","寵物過世","房屋損壞","租屋糾紛","搬家損失","家電故障","水管漏水","火災損失","失物遺失",
    "手機被盜","信用卡盜刷","網路詐騙","資金被騙","詐騙集團受害","旅行行李遺失","航班取消延誤","旅行計畫破滅","證件遺失","簽證被拒",
    "被拒絕合作","專案失敗","比賽落選","演出失敗","作品被退回","創業失敗","投資失敗","房產價值下跌","貸款糾紛","信用問題",
    "與長輩爭吵","家庭矛盾","兄弟姊妹爭執","家族聚會尷尬","親友冷淡","失去聯絡","友情破裂","被朋友忽視","社群被封鎖","網路爭議",
    "公眾羞辱","演講出錯","公開發言失誤","社交場合失態","公開表演失敗","重要場合出糗","被誤解","被責備","被否定","失去信任",
    "情感冷漠","親密失敗","第一次爭執","親密爭吵","約會失敗","戀愛失落","情人冷淡","分手爭執","失去情人","曖昧失敗",
    "暗戀被拒","戀愛失敗","第一次爭吵","戀愛挫折","親密事件失敗","愛情困惑","戀情破裂","感情失衡","第一次分手","熱戀冷淡",
    "親密關係中斷","同居爭吵","性生活摩擦","情感衝突","戀人外遇發現","感情危機","愛情冷戰","親密距離拉遠","戀愛糾紛","情感困擾",
    "家務爭執","日常摩擦","溝通不良","合作破裂","創業失敗","投資損失","工作合同取消","專案延遲","考試不及格","證書被取消"
])


# 否定詞（翻轉極性，作用範圍：前一個 token）
NEGATIONS = set(["不","沒","沒有","別","無","未","不太","不大","不怎麼"])
# 強度詞（加權）
STRONG_INTENSIFIERS = set(["超","超級","非常","爆","爆炸","巨","超級無敵","超級爆"])
WEAK_INTENSIFIERS = set(["很","挺","蠻","有點","稍微","有些","有","有一點"])

# 常見 emoji 的極性
EMOJI_POLARITY = {
    "😹": 3,"😻": 3,"😎": 3,"🥳": 3,"🤩": 3,"😀": 2, "😄": 2, "😁": 2, "🤣": 2, "😂": 2, "😊": 1, "🙂": 1, "😍": 2, "👍": 1, "✨": 1,
    "😐": 0, "🤔": 0, "😶": 0,
    "😕": -1,"💩": -1, "😞": -2,"🥲": -2, "😟": -2, "😢": -2, "😭": -3, "😡": -3, "🤬": -3, "👎": -1, "💔": -2,
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
