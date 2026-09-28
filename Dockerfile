# ═══════════════════════════════════════════════════════════════════
# CP2 — Containerization (production-ready)
#
#   [x] Multi-stage: `builder` cài dependency vào /install, `runtime` chỉ
#       copy kết quả sang → không mang pip cache / công cụ build vào image
#   [x] Base image python:3.11-slim cho cả hai stage
#   [x] COPY requirements.txt + pip install TRƯỚC khi COPY source code
#   [x] Chạy bằng user thường `appuser` (uid 10001), không phải root
#   [x] HEALTHCHECK gọi /health
#   [x] Đọc cổng từ biến PORT (mặc định 8000)
#
# Build:  docker build -t day12-agent:prod .
# ═══════════════════════════════════════════════════════════════════

# ── Stage 1: builder ───────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Chỉ copy requirements.txt → layer pip install được cache cho tới khi
# danh sách thư viện thay đổi, sửa code không làm cài lại.
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Stage 2: runtime ───────────────────────────────────────────────
FROM python:3.11-slim AS runtime

# PYTHONUNBUFFERED: log in ra ngay, không bị giữ trong buffer
# PYTHONDONTWRITEBYTECODE: không sinh file .pyc trong container
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000

RUN useradd --create-home --uid 10001 appuser

COPY --from=builder /install /usr/local

WORKDIR /app
COPY app ./app
COPY utils ./utils

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:${PORT:-8000}/health', timeout=4)" || exit 1

# `exec` để uvicorn thay thế shell và trở thành PID 1 → nhận được SIGTERM
# trực tiếp từ Docker/platform (cần cho graceful shutdown ở CP4).
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
