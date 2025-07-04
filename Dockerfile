FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install dependencies and Microsoft ODBC Driver 17 for SQL Server
RUN apt-get update && apt-get install -y \
    curl gnupg2 apt-transport-https unixodbc unixodbc-dev \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python packages
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the project
COPY . .

# Default command
CMD ["python", "scheduler.py"]
