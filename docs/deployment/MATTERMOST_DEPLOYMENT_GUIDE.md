# Mattermost Deployment Guide (AWS Lightsail)

This playbook documents the exact sequence to deploy Mattermost to AWS. It is written for an agentic LLM (e.g., Claude) that can run shell commands.

---

## 0. Requirements

| Tool | Notes |
| --- | --- |
| AWS CLI v2 | Must be configured with valid credentials |
| SSH | For accessing the Lightsail instance |
| Docker knowledge | Mattermost runs as Docker containers on the instance |

**Environment variables (.env in project root):**

```env
AWS_ACCESS_KEY_ID=your_key_here
AWS_SECRET_ACCESS_KEY=your_secret_here
AWS_DEFAULT_REGION=us-west-2
```

**Current Production Instance:**

| Property | Value |
| --- | --- |
| Instance Name | `mattermost-server` |
| Public IP | `35.88.175.112` |
| **Domain** | `mattermost-yibin.link` |
| Region | `us-west-2` |
| URL | <http://mattermost-yibin.link> |
| SSH User | `ubuntu` |
| Mattermost Port | 80 (mapped from container 8065) |
| Route 53 Hosted Zone | `Z09374349QDSOYOMBJ47` |

---

## 1. Loading AWS Credentials

Before any AWS CLI command, load the `.env` file:

```bash
set -a && source .env && set +a
```

---

## 2. First-Time Deployment (Fresh Instance)

Skip this section if the instance already exists. Use this only to create a new deployment from scratch.

### 2.1 Create the Lightsail Instance

```bash
set -a && source .env && set +a

AZ="${AWS_DEFAULT_REGION}a"

USER_DATA=$(cat <<'EOF'
#!/bin/bash
set -e
apt-get update
apt-get install -y docker.io docker-compose-v2
systemctl enable docker
systemctl start docker

mkdir -p /opt/mattermost/{config,data,logs,plugins,client-plugins,bleve-indexes}
chown -R 2000:2000 /opt/mattermost

cat > /opt/mattermost/docker-compose.yml <<'COMPOSE'
# Note: "version" attribute is obsolete in modern Docker Compose
services:
  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: mmuser
      POSTGRES_PASSWORD: mmuser_password
      POSTGRES_DB: mattermost
    volumes:
      - postgres_data:/var/lib/postgresql/data

  mattermost:
    image: mattermost/mattermost-team-edition:latest
    restart: unless-stopped
    depends_on:
      - postgres
    ports:
      - "80:8065"
    environment:
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: postgres://mmuser:mmuser_password@postgres:5432/mattermost?sslmode=disable&connect_timeout=10
      MM_SERVICESETTINGS_SITEURL: ""
      MM_TEAMSETTINGS_ENABLEOPENSERVER: "true"
    volumes:
      - /opt/mattermost/config:/mattermost/config
      - /opt/mattermost/data:/mattermost/data
      - /opt/mattermost/logs:/mattermost/logs
      - /opt/mattermost/plugins:/mattermost/plugins
      - /opt/mattermost/client-plugins:/mattermost/client/plugins
      - /opt/mattermost/bleve-indexes:/mattermost/bleve-indexes
    command: mattermost server

volumes:
  postgres_data:
COMPOSE

cd /opt/mattermost
docker compose up -d

# Wait for containers to initialize, then fix any permission issues
sleep 30
chown -R 2000:2000 /opt/mattermost/config
chown -R 2000:2000 /opt/mattermost/data
chown -R 2000:2000 /opt/mattermost/logs
chown -R 2000:2000 /opt/mattermost/plugins
docker compose restart mattermost
EOF
)

aws lightsail create-instances \
  --instance-names "mattermost-server" \
  --availability-zone "$AZ" \
  --blueprint-id "ubuntu_24_04" \
  --bundle-id "medium_3_0" \
  --user-data "$USER_DATA"
```

### 2.2 Open Firewall Ports

```bash
set -a && source .env && set +a

aws lightsail open-instance-public-ports \
  --instance-name "mattermost-server" \
  --port-info fromPort=80,toPort=80,protocol=tcp

aws lightsail open-instance-public-ports \
  --instance-name "mattermost-server" \
  --port-info fromPort=443,toPort=443,protocol=tcp
```

### 2.3 Get Public IP

```bash
set -a && source .env && set +a
aws lightsail get-instance --instance-name "mattermost-server" \
  --query "instance.publicIpAddress" --output text
```

### 2.4 Verify Deployment

Wait 3-5 minutes for Docker to pull images and start containers, then:

```bash
curl -s -I http://<PUBLIC_IP> | head -5
```

Expected: `HTTP/1.1 200 OK`

---

## 3. SSH Access to Instance

### 3.1 Download SSH Key

```bash
set -a && source .env && set +a
aws lightsail download-default-key-pair --query 'privateKeyBase64' --output text > /tmp/lightsail-key.pem
chmod 600 /tmp/lightsail-key.pem
```

### 3.2 SSH Into Instance

```bash
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112
```

> **Note for automation:** The `-o StrictHostKeyChecking=no` flag prevents SSH from prompting about unknown hosts. All SSH commands in this guide include this flag for agentic use.

---

## 4. Deploying Code Changes (RECOMMENDED METHOD)

When you need to deploy updated Mattermost code (custom build):

> **IMPORTANT WARNING FOR AGENTIC LLMs:** The `make package-linux-amd64` command creates a tar file with a problematic structure. It contains both `mattermost/` (binaries) and `../mattermost/` (resources) paths. GNU tar on Linux **blocks extraction of `..` paths for security reasons**, causing silent failures. You MUST use the repackaging method below.

### 4.1 Build the Webapp and Server

On your local machine:

```bash
cd /Users/yibin/Documents/WORKZONE/VSCODE/GAUNTLET_AI/8_Week/MatterMostAI

# Step 1: Build the webapp (if you have frontend changes)
cd webapp && make dist && cd ..

# Step 2: Build the server binary for Linux
cd server
make build-linux-amd64

# Step 3: Run the package command (creates dist/ directories)
make package-linux-amd64
```

### 4.2 Repackage the Tar File (CRITICAL STEP)

The generated tar file has broken paths. You MUST repackage it locally:

```bash
cd /Users/yibin/Documents/WORKZONE/VSCODE/GAUNTLET_AI/8_Week/MatterMostAI/server

# Create a clean package directory
rm -rf /tmp/mm_repack
mkdir -p /tmp/mm_repack/mattermost/bin
mkdir -p /tmp/mm_repack/mattermost/logs

# Copy resources (webapp, templates, i18n, config, fonts)
cp -r dist/mattermost/* /tmp/mm_repack/mattermost/

# Copy the Linux binaries
cp bin/linux_amd64/mattermost /tmp/mm_repack/mattermost/bin/
cp bin/linux_amd64/mmctl /tmp/mm_repack/mattermost/bin/

# Create the fixed tar file
cd /tmp/mm_repack
tar -czf mattermost-deploy.tar.gz mattermost

# Verify the tar structure (should show mattermost/ not ../mattermost/)
tar -tzf mattermost-deploy.tar.gz | head -10
```

### 4.3 Upload and Deploy to Instance

```bash
# Download SSH key (if not already done)
set -a && source /Users/yibin/Documents/WORKZONE/VSCODE/GAUNTLET_AI/8_Week/MatterMostAI/.env && set +a
aws lightsail download-default-key-pair --query 'privateKeyBase64' --output text > /tmp/lightsail-key.pem
chmod 600 /tmp/lightsail-key.pem

# Upload the fixed tar file
scp -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem /tmp/mm_repack/mattermost-deploy.tar.gz ubuntu@35.88.175.112:/tmp/

# Deploy on the instance
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 "
cd /opt/mattermost && \
sudo docker compose down && \
sudo rm -rf mattermost && \
sudo tar -xzf /tmp/mattermost-deploy.tar.gz && \
sudo chown -R 2000:2000 mattermost && \
sudo docker build -t mattermost-custom:latest . && \
sudo docker compose up -d
"
```

### 4.4 Verify Deployment

```bash
# Wait 15-20 seconds for startup, then verify
curl -s -o /dev/null -w "%{http_code}" http://mattermost-yibin.link
# Expected: 200

# Check container logs if needed
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 \
  "sudo docker logs mattermost-mattermost-1 --tail 20"
```

### 4.5 Instance Dockerfile (Already Configured)

The instance at `/opt/mattermost/Dockerfile` is already configured:

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y ca-certificates tzdata && rm -rf /var/lib/apt/lists/*

WORKDIR /mattermost

COPY mattermost/ /mattermost/

RUN useradd -u 2000 -U -m mattermost && \
    mkdir -p /mattermost/config /mattermost/data /mattermost/logs /mattermost/plugins /mattermost/client/plugins /mattermost/bleve-indexes && \
    chown -R mattermost:mattermost /mattermost

USER mattermost
EXPOSE 8065
ENTRYPOINT ["/mattermost/bin/mattermost"]
CMD ["server"]
```

### 4.6 Instance docker-compose.yml (Already Configured)

The instance at `/opt/mattermost/docker-compose.yml`:

```yaml
services:
  postgres:
    image: postgres:15-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: mmuser
      POSTGRES_PASSWORD: mmuser_password
      POSTGRES_DB: mattermost
    volumes:
      - postgres_data:/var/lib/postgresql/data

  mattermost:
    image: mattermost-custom:latest
    restart: unless-stopped
    depends_on:
      - postgres
    ports:
      - "80:8065"
    environment:
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: postgres://mmuser:mmuser_password@postgres:5432/mattermost?sslmode=disable&connect_timeout=10
      MM_SERVICESETTINGS_SITEURL: ""
      MM_TEAMSETTINGS_ENABLEOPENSERVER: "true"
    volumes:
      - /opt/mattermost/config:/mattermost/config
      - /opt/mattermost/data:/mattermost/data
      - /opt/mattermost/logs:/mattermost/logs
      - /opt/mattermost/plugins:/mattermost/plugins
      - /opt/mattermost/client-plugins:/mattermost/client/plugins
      - /opt/mattermost/bleve-indexes:/mattermost/bleve-indexes

volumes:
  postgres_data:
```

### 4.7 Alternative: Direct Binary Update (Quick Fixes Only)

For server-only changes (no webapp changes), you can update just the binary:

```bash
# Copy binary to instance
scp -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem \
  /Users/yibin/Documents/WORKZONE/VSCODE/GAUNTLET_AI/8_Week/MatterMostAI/server/bin/linux_amd64/mattermost \
  ubuntu@35.88.175.112:/tmp/

# Replace binary and restart
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 "
sudo docker compose -f /opt/mattermost/docker-compose.yml down && \
sudo cp /tmp/mattermost /opt/mattermost/mattermost/bin/mattermost && \
sudo chown 2000:2000 /opt/mattermost/mattermost/bin/mattermost && \
sudo docker build -t mattermost-custom:latest /opt/mattermost && \
sudo docker compose -f /opt/mattermost/docker-compose.yml up -d
"
```

---

## 5. Useful Commands

### Check Instance Status

```bash
set -a && source .env && set +a
aws lightsail get-instance --instance-name "mattermost-server" \
  --query "instance.{state:state.name,ip:publicIpAddress}" --output table
```

### View Container Logs

```bash
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 \
  "sudo docker logs mattermost-mattermost-1 --tail 50"
```

### Restart Mattermost

```bash
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 \
  "cd /opt/mattermost && sudo docker compose restart"
```

### Stop Mattermost

```bash
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 \
  "cd /opt/mattermost && sudo docker compose down"
```

### Start Mattermost

```bash
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 \
  "cd /opt/mattermost && sudo docker compose up -d"
```

### Check Container Health

```bash
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 "sudo docker ps"
```

---

## 6. Delete Instance (Cleanup)

To completely remove the deployment:

```bash
set -a && source .env && set +a
aws lightsail delete-instance --instance-name mattermost-server
```

---

## 7. Troubleshooting

| Problem | Action |
| --- | --- |
| Can't connect to instance | Check `aws lightsail get-instance-port-states --instance-name mattermost-server` |
| Mattermost not loading | SSH in and check `sudo docker ps` - containers should be "Up" |
| Container restarting | Check logs: `sudo docker logs mattermost-mattermost-1` |
| Permission denied errors | Run `sudo chown -R 2000:2000 /opt/mattermost` on instance |
| Database connection failed | Check postgres container: `sudo docker logs mattermost-postgres-1` |
| SSH key issues | Re-download: `aws lightsail download-default-key-pair` |
| **"unable to find i18n directory"** | Tar extraction failed silently. The `make package-linux-amd64` tar has `../mattermost/` paths that GNU tar blocks. You MUST repackage locally (see Section 4.2) |
| **Tar shows "Member name contains '..'"** | This is the broken tar structure. Repackage the tar file locally before uploading (see Section 4.2) |
| Missing templates/fonts/client | Same root cause as i18n - tar extraction issue. Repackage locally |
| Container logs show startup but no web response | Check if `/mattermost/client/` exists in container: `sudo docker exec mattermost-mattermost-1 ls /mattermost/client/` |

### Common Tar Extraction Issue (For Agentic LLMs)

If you see errors like:
```
tar: ../mattermost/: Member name contains '..'
tar: ../mattermost/config/: Member name contains '..'
tar: Exiting with failure status due to previous errors
```

**This is expected behavior from the broken tar file.** GNU tar blocks `..` paths for security. The tar file created by `make package-linux-amd64` has this structure:
- `mattermost/` - contains only `bin/`, `logs/`, `prepackaged_plugins/`
- `../mattermost/` - contains `client/`, `config/`, `fonts/`, `i18n/`, `templates/` (BLOCKED)

**Solution:** Always repackage locally using the method in Section 4.2 before uploading to the server.

---

## 8. Domain Management (Route 53)

The domain `mattermost-yibin.link` is registered through AWS Route 53 and points to the Mattermost server.

### DNS Records

| Record | Type | Value |
| --- | --- | --- |
| `mattermost-yibin.link` | A | `35.88.175.112` |
| `www.mattermost-yibin.link` | A | `35.88.175.112` |

### Update DNS Record (if IP changes)

```bash
set -a && source .env && set +a

aws route53 change-resource-record-sets \
  --hosted-zone-id "Z09374349QDSOYOMBJ47" \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "mattermost-yibin.link",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "NEW_IP_HERE"}]
      }
    }]
  }'
```

### Check Domain Registration Status

```bash
set -a && source .env && set +a
aws route53domains get-domain-detail --domain-name mattermost-yibin.link --region us-east-1
```

---

## 9. Quick Reference

**Production URL:** <http://mattermost-yibin.link>

**One-liner to verify deployment:**

```bash
curl -s -o /dev/null -w "%{http_code}" http://mattermost-yibin.link
```

Expected output: `200`

**One-liner to restart containers (no rebuild):**

```bash
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 "cd /opt/mattermost && sudo docker compose down && sudo docker compose up -d"
```

**One-liner to rebuild and restart (after uploading new tar):**

```bash
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 "cd /opt/mattermost && sudo docker compose down && sudo rm -rf mattermost && sudo tar -xzf /tmp/mattermost-deploy.tar.gz && sudo chown -R 2000:2000 mattermost && sudo docker build -t mattermost-custom:latest . && sudo docker compose up -d"
```

**Full deployment from local machine (after building):**

```bash
# Assumes you've already run: make build-linux-amd64 && make package-linux-amd64

# 1. Repackage locally
cd /Users/yibin/Documents/WORKZONE/VSCODE/GAUNTLET_AI/8_Week/MatterMostAI/server && \
rm -rf /tmp/mm_repack && \
mkdir -p /tmp/mm_repack/mattermost/{bin,logs} && \
cp -r dist/mattermost/* /tmp/mm_repack/mattermost/ && \
cp bin/linux_amd64/{mattermost,mmctl} /tmp/mm_repack/mattermost/bin/ && \
cd /tmp/mm_repack && tar -czf mattermost-deploy.tar.gz mattermost

# 2. Upload and deploy
scp -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem /tmp/mm_repack/mattermost-deploy.tar.gz ubuntu@35.88.175.112:/tmp/ && \
ssh -o StrictHostKeyChecking=no -i /tmp/lightsail-key.pem ubuntu@35.88.175.112 "cd /opt/mattermost && sudo docker compose down && sudo rm -rf mattermost && sudo tar -xzf /tmp/mattermost-deploy.tar.gz && sudo chown -R 2000:2000 mattermost && sudo docker build -t mattermost-custom:latest . && sudo docker compose up -d"

# 3. Verify
sleep 20 && curl -s -o /dev/null -w "%{http_code}" http://mattermost-yibin.link
```
