# Phiếu Phản Ánh — K4 Level 3A, Ngày 12

> **Bài làm cá nhân.** Trả lời bằng lời của chính bạn, dựa trên những gì bạn
> quan sát được khi chạy code — không sao chép đáp án của người khác.
>
> Cách trả lời: thay dòng `> *Câu trả lời của bạn*` bằng câu trả lời.
> `grade.py` đếm số câu đã trả lời (15 điểm cho 10 câu).
>
> Họ và tên: Lê Chí Hùng  Mã học viên: 2A202602863

---

### Câu 1 — Fail fast (CP1)

Trong `Settings`, `agent_api_key` không có giá trị mặc định nên app chết ngay
khi khởi động nếu thiếu biến môi trường. Hãy mô tả một tình huống cụ thể mà
việc "chết sớm" này cứu bạn, so với việc để mặc định `"changeme"`.

> Nếu để mặc định là changeme thì mọi thứ đều hoạt động. Và khi mà bị lộ là changeme thì người khác cũng gọi được /ask. Còn nếu không có mặc định thì sẽ lỗi luôn và mình phát hiện ngay lúc đó.

---

### Câu 2 — Log cho máy đọc (CP1)

Chạy service và gọi `/ask` vài lần. Dán một dòng log JSON bạn thu được, rồi
nêu **hai** việc bạn làm được với dòng log đó mà `print("đã trả lời xong")`
không làm được.

> {"event": "ask_completed", "level": "info", "timestamp": "2026-09-28T08:41:32.932951+00:00", "user_id": "sv01", "tokens_in": 445, "tokens_out": 47, "cost_usd": 9.495e-05}. Việc có thể làm với log mà print không làm được là: Lọc, cộng dồn theo trường như user và cost. Biết được số token in và out.

---

### Câu 3 — Kích thước image (CP2)

Build cả hai phiên bản và ghi lại số đo thật:

```bash
docker build -f <Dockerfile-1-stage> -t agent:single .
docker build -t agent:multi .
docker images | grep agent
```

| Bản | Dung lượng |
|-----|-----------|
| 1 stage (bản đầu) | 1.73 GB |
| Multi-stage | 271 MB |

Giải thích: phần dung lượng chênh lệch đó là những gì?

> Chênh lệch chủ yếu đến từ base image, 1 stage dùng python:3.11 nặng hơn bản multi dùng python:3.11-slim

---

### Câu 4 — Thứ tự lệnh trong Dockerfile (CP2)

Sửa một ký tự trong `app/main.py` rồi build lại. Với Dockerfile của bạn, những
layer nào được dùng lại từ cache, layer nào phải chạy lại? Nếu bạn đặt
`COPY . .` lên trước `RUN pip install` thì kết quả khác thế nào?

> Dùng lại từ cache: tất cả các layer không liên quan đến code: Stage builder và runtime. Phần chạy lại: COPY app ./app (vì main.py đổi) và COPY utils ./utils. Nếu đặt COPY . . lên trước RUN pip install, như Dockerfile gốc: Docker hủy cache từ layer đầu tiên thay đổi trở đi, nên RUN pip install phải chạy lại từ đầu: tải và cài lại toàn bộ thư viện, dù requirements.txt không hề đổi.

---

### Câu 5 — Vì sao không chạy bằng root (CP2)

Container mặc định chạy bằng root. Mô tả chuỗi sự kiện dẫn từ "một lỗ hổng
trong code Python của bạn" tới "kẻ tấn công có quyền cao trên máy host", và
lệnh `USER` cắt đứt chuỗi đó ở chỗ nào.

> Code có lỗ hổng (vd command injection) → kẻ tấn công chạy được lệnh trong container, và vì container chạy root nên họ có quyền root trong đó: sửa code, đọc secret, cài công cụ → root trong container cũng là root trên host, nên chỉ cần thêm một điểm yếu (volume mount từ host, `docker.sock`, CVE kernel) là thoát ra được host với quyền root. `USER appuser` cắt ở bước đầu: kẻ tấn công chỉ là user thường, không sửa được `/app` hay `/usr/local` (thuộc root), và nếu có thoát ra thì cũng không có quyền gì trên host.

---

### Câu 6 — Cửa sổ trượt (CP3)

Rate limit của bạn dùng sliding window 60 giây. Nếu thay bằng cách đếm theo
phút đồng hồ (reset lúc giây 00), một người dùng có thể gửi tối đa bao nhiêu
request trong 2 giây liên tiếp khi hạn mức là 10/phút? Giải thích cách đạt được
con số đó.

> Tối đa **20 request**: gửi 10 request lúc 16:30:59, sang 16:31:00 bộ đếm reset nên gửi tiếp được 10 nữa. Sliding window thì không bị vậy, vì lúc 16:31:00 nó vẫn đếm được 10 request trong 60 giây trước đó nên trả 429.

---

### Câu 7 — Rate limit và cost guard (CP3)

Hai cơ chế này khác nhau ở điểm nào? Cho một tình huống mà rate limit cho qua
nhưng cost guard phải chặn, và một tình huống ngược lại.

> Rate limit giới hạn **số request** trong 60 giây (429), cost guard giới hạn **số tiền** trong tháng (402). Rate limit cho qua nhưng cost guard chặn: user gọi chậm, dưới 10 request/phút, nhưng mỗi câu tốn nhiều token nên dồn lại nhiều ngày thì vượt 10 USD. Ngược lại: user spam 15 câu ngắn trong vài giây, tốn rất ít tiền nhưng bị 429 từ lần thứ 11 (test trên Railway mình thấy `200 ×9` rồi `429 ×6`).

---

### Câu 8 — /health khác /ready (CP4)

Nếu gộp hai endpoint làm một và cho nó kiểm tra Redis, chuyện gì xảy ra với cụm
3 container khi Redis mất kết nối 30 giây? Trả lời theo đúng thứ tự sự kiện.

> Redis mất kết nối → endpoint gộp của cả 3 container cùng trả 503 (vì dùng chung một Redis) → load balancer thấy cả 3 đều lỗi nên mọi request đều bị 502 → health check fail vài lần liên tiếp, orchestrator restart cả 3 cùng lúc → Redis quay lại sau 30 giây nhưng container vẫn đang khởi động, nên cả cụm bị gián đoạn lâu hơn 30 giây. Tách riêng thì `/health` vẫn 200 nên không container nào bị restart, chỉ `/ready` trả 503 trong lúc Redis mất, Redis quay lại là chạy lại bình thường.

---

### Câu 9 — Stateless (CP4)

Chạy `docker compose up --scale agent=3` rồi gọi `/ask` nhiều lần với cùng một
`X-User-Id`. Quan sát `history_length` trong response. Nếu lịch sử được lưu
trong một dict Python thay vì Redis, bạn sẽ thấy con số đó thay đổi thế nào?

> Mình chạy 3 agent sau nginx, gọi 6 lần cùng một user. Với Redis: `history_length` = `0 2 4 6 8 10`, vì cả 3 container dùng chung một lịch sử. Khi mỗi container lưu lịch sử trong RAM (mình thử bằng `REDIS_URL=fake://`, giống dùng dict): `0 0 0 2 2 2`, vì request rơi vào container khác nhau và mỗi container chỉ nhớ phần lịch sử của nó, nên agent bị "mất trí nhớ".

---

### Câu 10 — Deploy thật (CP5)

Ghi lại **một** lỗi bạn gặp khi deploy lên cloud (build fail, health check
timeout, sai REDIS_URL, app không đọc `$PORT`...): thông báo lỗi là gì, bạn
tìm ra nguyên nhân bằng cách nào, và sửa ra sao?

> Lần deploy lên Railway của mình thành công ngay, vì lỗi đã được sửa trước khi deploy. File `railway.toml` mẫu có `startCommand = "uvicorn ... --port $PORT"`. Với service build từ Dockerfile, Railway không thay `$PORT` bằng giá trị thật trong dòng này, nên uvicorn sẽ báo lỗi `'$PORT' is not a valid integer` và container không khởi động được. Mình xóa `startCommand` để Railway dùng `CMD` trong Dockerfile (`sh -c "exec uvicorn ... --port ${PORT:-8000}"`), rồi kiểm tra `railway logs` thấy `Uvicorn running on http://0.0.0.0:8080`, tức app đã đọc đúng cổng Railway gán.
