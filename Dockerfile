FROM python:3.12-slim AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /build

# Copy only requirements first
COPY app/requirements.txt .

# Install dependencies into a separate directory
RUN pip install --prefix=/install --no-cache-dir -r requirements.txt

# ---- runtime stage ----
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 10001 appgroup && adduser --system --uid 10001 --ingroup appgroup appuser

# Copy installed dependencies from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY --chown=10001:10001 app/ ./app

# Expose port
EXPOSE 8080

# Switch to non-root user
USER 10001:10001

# Container-level health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=2)" || exit 1

# default Gunicorn command 
CMD ["gunicorn", "--chdir", "app", "--bind", "0.0.0.0:8080", "--workers", "2", "app:app"]