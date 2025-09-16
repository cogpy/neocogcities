# Deployment Guide

## Overview

This guide covers the deployment architecture, infrastructure requirements, and deployment procedures for Neocities.

## Infrastructure Architecture

```mermaid
graph TB
    subgraph "Production Environment"
        subgraph "Load Balancing"
            LB[Load Balancer<br/>nginx/HAProxy]
            SSL[SSL Termination<br/>Let's Encrypt]
        end
        
        subgraph "Application Tier"
            App1[App Server 1<br/>Puma/Unicorn]
            App2[App Server 2<br/>Puma/Unicorn]
            AppN[App Server N<br/>Puma/Unicorn]
        end
        
        subgraph "Background Processing"
            Worker1[Sidekiq Worker 1]
            Worker2[Sidekiq Worker 2]
            WorkerN[Sidekiq Worker N]
        end
        
        subgraph "Data Layer"
            PG[(PostgreSQL<br/>Primary)]
            PGRead[(PostgreSQL<br/>Read Replica)]
            Redis[(Redis<br/>Cache & Jobs)]
            Files[File Storage<br/>Local/S3]
        end
        
        subgraph "Monitoring"
            Metrics[Metrics<br/>Prometheus]
            Logs[Centralized Logging<br/>ELK Stack]
            APM[APM<br/>Airbrake]
        end
    end
    
    Internet --> LB
    LB --> SSL
    SSL --> App1
    SSL --> App2
    SSL --> AppN
    
    App1 --> PG
    App2 --> PG
    AppN --> PG
    
    App1 --> PGRead
    App2 --> PGRead
    AppN --> PGRead
    
    App1 --> Redis
    App2 --> Redis
    AppN --> Redis
    
    Worker1 --> PG
    Worker2 --> PG
    WorkerN --> PG
    
    Worker1 --> Redis
    Worker2 --> Redis
    WorkerN --> Redis
    
    App1 --> Files
    App2 --> Files
    AppN --> Files
    
    Worker1 --> Files
    Worker2 --> Files
    WorkerN --> Files
    
    App1 --> Metrics
    App2 --> Metrics
    AppN --> Metrics
    
    Worker1 --> Logs
    Worker2 --> Logs
    WorkerN --> Logs
```

## System Requirements

### Minimum Hardware Requirements

#### Application Servers
- **CPU**: 2-4 cores per server
- **RAM**: 4-8 GB per server
- **Storage**: 20-50 GB SSD for application and logs
- **Network**: 1 Gbps connection

#### Database Server
- **CPU**: 4-8 cores
- **RAM**: 16-32 GB (25% of database size + working set)
- **Storage**: High-performance SSD with good IOPS
- **Network**: 1 Gbps connection

#### File Storage
- **Storage**: Depends on user growth (TB scale)
- **Performance**: High throughput for file uploads/downloads
- **Backup**: Regular snapshots and off-site backups

### Software Requirements

#### Operating System
- Ubuntu 20.04+ LTS or CentOS 8+
- Security updates applied regularly
- NTP synchronization configured

#### Runtime Dependencies
- Ruby 3.0+
- PostgreSQL 13+
- Redis 6+
- nginx 1.18+
- Node.js 16+ (for asset compilation)

## Deployment Process

### 1. Environment Setup

#### System Dependencies
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y git curl build-essential libssl-dev libreadline-dev \
  zlib1g-dev libpq-dev imagemagick libmagickwand-dev nodejs npm

# Ruby installation (via rbenv)
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
rbenv install 3.0.0
rbenv global 3.0.0
```

#### Database Setup
```bash
# PostgreSQL installation and setup
sudo apt install postgresql postgresql-contrib
sudo -u postgres createuser -s neocities
sudo -u postgres createdb neocities_production
```

#### Redis Setup
```bash
sudo apt install redis-server
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

### 2. Application Deployment

#### Code Deployment
```bash
# Clone repository
git clone https://github.com/neocities/neocities.git /opt/neocities
cd /opt/neocities

# Install dependencies
bundle install --deployment --without development test
npm install

# Setup configuration
cp config.yml.template config.yml
# Edit config.yml with production settings

# Compile assets
bundle exec sass sass:public/css --style compressed

# Run database migrations
bundle exec rake db:migrate
```

#### Configuration Management
```yaml
# config.yml (production section)
production:
  database: postgresql://neocities:password@localhost/neocities_production
  redis_url: redis://localhost:6379/0
  sidekiq_url: redis://localhost:6379/1
  
  # Security
  session_secret: "your-secret-key-here"
  csrf_secret: "your-csrf-secret-here"
  
  # External services
  stripe_api_key: "sk_live_..."
  email_smtp_server: "smtp.mailgun.org"
  
  # File storage
  files_path: "/var/neocities/files"
  
  # Performance
  database_pool: 10
  worker_concurrency: 25
```

### 3. Process Management

#### Systemd Service Files

**Application Server** (`/etc/systemd/system/neocities-web.service`):
```ini
[Unit]
Description=Neocities Web Application
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=neocities
WorkingDirectory=/opt/neocities
Environment=RACK_ENV=production
ExecStart=/usr/local/bin/bundle exec puma -C puma_config.rb
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Background Workers** (`/etc/systemd/system/neocities-workers.service`):
```ini
[Unit]
Description=Neocities Background Workers
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=neocities
WorkingDirectory=/opt/neocities
Environment=RACK_ENV=production
ExecStart=/usr/local/bin/bundle exec sidekiq -c 25 -e production
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### Process Control
```bash
# Enable and start services
sudo systemctl enable neocities-web neocities-workers
sudo systemctl start neocities-web neocities-workers

# Check status
sudo systemctl status neocities-web neocities-workers

# View logs
sudo journalctl -u neocities-web -f
sudo journalctl -u neocities-workers -f
```

### 4. Load Balancer Configuration

#### nginx Configuration
```nginx
upstream neocities {
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
    # Add more app servers as needed
}

server {
    listen 80;
    server_name neocities.org www.neocities.org;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name neocities.org www.neocities.org;
    
    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/neocities.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/neocities.org/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    
    # File upload limits
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://neocities;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
    
    # Static file serving
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|otf)$ {
        root /opt/neocities/public;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # User site files
    location ~ ^/([^/]+)/(.*)$ {
        alias /var/neocities/files/$1/$2;
        expires 1h;
        add_header Cache-Control "public";
    }
}
```

## Scaling Strategies

### Horizontal Scaling

#### Application Servers
```mermaid
graph LR
    LB[Load Balancer] --> App1[App Server 1]
    LB --> App2[App Server 2]
    LB --> App3[App Server 3]
    LB --> AppN[App Server N]
    
    App1 --> DB[(Database)]
    App2 --> DB
    App3 --> DB
    AppN --> DB
```

**Scaling Process:**
1. Provision new application server
2. Deploy application code
3. Configure monitoring
4. Add to load balancer pool
5. Verify health checks pass

#### Background Workers
```bash
# Scale workers based on queue size
QUEUE_SIZE=$(redis-cli llen queue:default)
if [ $QUEUE_SIZE -gt 100 ]; then
    # Start additional worker processes
    sudo systemctl start neocities-workers@2
fi
```

### Database Scaling

#### Read Replicas
```yaml
# config.yml - Read replica configuration
production:
  database: postgresql://neocities:password@primary-db/neocities_production
  read_database: postgresql://neocities:password@replica-db/neocities_production
```

#### Connection Pooling
```ruby
# Use pgbouncer for connection pooling
DB = Sequel.connect(
  $config['database'],
  max_connections: 20,
  pool_timeout: 5
)
```

### File Storage Scaling

#### Distributed Storage
```yaml
# Object storage configuration
production:
  file_storage:
    type: s3
    bucket: neocities-files
    region: us-east-1
    access_key_id: AKIA...
    secret_access_key: "..."
```

## Monitoring & Observability

### Application Monitoring

#### Health Checks
```ruby
# Health check endpoint
get '/health' do
  status 200
  content_type :json
  
  {
    status: 'healthy',
    database: DB.test_connection ? 'connected' : 'disconnected',
    redis: $redis.ping == 'PONG' ? 'connected' : 'disconnected',
    timestamp: Time.now.iso8601
  }.to_json
end
```

#### Metrics Collection
```yaml
# Prometheus metrics endpoint
get '/metrics' do
  content_type 'text/plain'
  
  # Expose application metrics
  metrics = [
    "neocities_requests_total #{@request_count}",
    "neocities_active_users #{Site.active_users_count}",
    "neocities_file_uploads_total #{@upload_count}"
  ]
  
  metrics.join("\n")
end
```

### Infrastructure Monitoring

#### System Metrics
- CPU usage and load average
- Memory utilization
- Disk space and IOPS
- Network throughput
- Process counts

#### Database Monitoring
- Connection pool usage
- Query execution time
- Lock contention
- Replication lag
- Disk space usage

#### Application Metrics
- Request rate and response time
- Error rate and error types
- Background job queue sizes
- User registration and activity
- File upload/download rates

## Security Considerations

### Network Security
- Firewall rules restricting access
- VPN for administrative access
- Regular security updates
- Intrusion detection system

### Application Security
- Regular dependency updates
- Security headers configuration
- Input validation and sanitization
- Rate limiting and DDoS protection

### Data Security
- Database encryption at rest
- SSL/TLS for data in transit
- Regular security audits
- Access logging and monitoring

## Backup & Disaster Recovery

### Database Backups
```bash
#!/bin/bash
# Daily database backup script
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/postgresql"

pg_dump -h localhost -U neocities neocities_production | \
  gzip > "${BACKUP_DIR}/neocities_${DATE}.sql.gz"

# Upload to S3
aws s3 cp "${BACKUP_DIR}/neocities_${DATE}.sql.gz" \
  s3://neocities-backups/database/
```

### File Backups
```bash
#!/bin/bash
# File storage backup
DATE=$(date +%Y%m%d)
rsync -av --delete /var/neocities/files/ \
  /backups/files_${DATE}/

# Sync to off-site storage
aws s3 sync /backups/files_${DATE}/ \
  s3://neocities-backups/files/${DATE}/
```

### Recovery Procedures
1. **Database Recovery**: Restore from latest backup and replay WAL files
2. **File Recovery**: Restore from latest file backup
3. **Application Recovery**: Deploy from git repository and restore configuration
4. **Verification**: Run health checks and verify functionality

## Deployment Automation

### CI/CD Pipeline
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.0.0
          bundler-cache: true
      
      - name: Run tests
        run: bundle exec rake test
      
      - name: Deploy to production
        run: |
          # Deploy script
          ./scripts/deploy.sh production
```

### Zero-Downtime Deployment
1. Deploy new version to staging
2. Run health checks on staging
3. Deploy to subset of production servers
4. Verify functionality
5. Complete rolling deployment
6. Update load balancer configuration