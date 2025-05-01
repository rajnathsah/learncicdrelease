# =========================================================================
# Stage 1: Build
# =========================================================================
FROM python:3.10-alpine AS builder

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /build

# Install build-time dependencies
RUN apk add --no-cache gcc musl-dev libffi-dev \
    && apk add --no-cache --virtual .build-deps build-base

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --upgrade pip \
    && pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

# =========================================================================
# Stage 2: Runtime
# =========================================================================
FROM python:3.10-alpine AS final

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set the working directory
WORKDIR /app

# Install runtime dependencies
RUN apk add --no-cache libffi

# Create a non-root user
RUN addgroup -S appgroup && adduser -S -G appgroup appuser

# Copy dependencies from the builder stage
COPY --from=builder /wheels /wheels
COPY requirements.txt .
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt \
    && rm -rf /wheels

# Copy application code
COPY . .

# Expose the application port
EXPOSE 8000

# Switch to the non-root user
USER appuser

# Define the command to run the application
CMD ["fastapi", "run", "main.py", "--port", "8000"]

# Add metadata labels
LABEL maintainer="Your Name <your.email@example.com>"
LABEL description="Optimized Dockerfile for the Python application"