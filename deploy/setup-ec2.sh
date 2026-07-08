#!/bin/bash
# One-time EC2 setup script for FluxFi
# Run as ec2-user on Amazon Linux 2023

set -e

echo "=== Installing Docker ==="
sudo yum update -y
sudo yum install -y docker git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

echo "=== Installing Docker Compose ==="
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "=== Cloning repository ==="
cd /home/ec2-user
git clone https://github.com/apuroopy1-prog/FluxFi.git fluxfi
cd fluxfi

echo "=== Creating .env file ==="
cat > .env << 'ENVFILE'
POSTGRES_USER=fluxfi
POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD
POSTGRES_DB=fluxfi_db
SECRET_KEY=CHANGE_ME_RANDOM_64_CHAR_STRING
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7
OPENAI_API_KEY=your_openai_key_here
ALLOWED_ORIGINS=http://YOUR_EC2_IP
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=http://YOUR_EC2_IP/api/gmail/callback
ENVFILE

echo ""
echo "=== IMPORTANT: Edit .env with real values before continuing ==="
echo "  nano .env"
echo ""
echo "Then run: ./deploy/deploy.sh"
