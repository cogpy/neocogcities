# Database Schema Documentation

## Overview

Neocities uses PostgreSQL as its primary database with the Sequel ORM for Ruby. The schema is designed to support multi-tenant website hosting with social features, analytics, and content management.

## Core Tables

### sites
The central table representing user accounts and their websites.

```sql
CREATE TABLE sites (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Site configuration
    domain VARCHAR(255),
    title VARCHAR(255),
    description TEXT,
    profile_enabled BOOLEAN DEFAULT false,
    
    -- Status flags
    is_deleted BOOLEAN DEFAULT false,
    is_banned BOOLEAN DEFAULT false,
    email_confirmed BOOLEAN DEFAULT false,
    phone_verified BOOLEAN DEFAULT false,
    
    -- Analytics
    views INTEGER DEFAULT 0,
    hits INTEGER DEFAULT 0,
    score FLOAT DEFAULT 0.0,
    site_changed BOOLEAN DEFAULT false,
    
    -- Subscription
    plan_type VARCHAR(50) DEFAULT 'free',
    plan_expires TIMESTAMP,
    supporter_since TIMESTAMP,
    
    -- Verification
    email_confirm_token VARCHAR(255),
    phone_confirm_token VARCHAR(255),
    password_reset_token VARCHAR(255),
    password_reset_expires TIMESTAMP
);

-- Indexes
CREATE INDEX idx_sites_username ON sites(username);
CREATE INDEX idx_sites_domain ON sites(domain);
CREATE INDEX idx_sites_email ON sites(email);
CREATE INDEX idx_sites_score ON sites(score DESC);
CREATE INDEX idx_sites_created_at ON sites(created_at DESC);
```

### site_files
Stores metadata for all files uploaded to user sites.

```sql
CREATE TABLE site_files (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    path VARCHAR(500) NOT NULL,
    size INTEGER NOT NULL DEFAULT 0,
    is_directory BOOLEAN DEFAULT false,
    mime_type VARCHAR(255),
    sha1_hash VARCHAR(40),
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Processing status
    classifier VARCHAR(50), -- 'phishing', 'spam', 'ham', null
    thumbnail_generated BOOLEAN DEFAULT false,
    screenshot_generated BOOLEAN DEFAULT false
);

-- Indexes
CREATE UNIQUE INDEX idx_site_files_site_path ON site_files(site_id, path);
CREATE INDEX idx_site_files_mime_type ON site_files(mime_type);
CREATE INDEX idx_site_files_size ON site_files(size);
CREATE INDEX idx_site_files_updated_at ON site_files(updated_at DESC);
```

## Social Features

### tags
Global tags that can be applied to sites.

```sql
CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tags_name ON tags(name);
```

### sites_tags
Many-to-many relationship between sites and tags.

```sql
CREATE TABLE sites_tags (
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    tag_id INTEGER NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    PRIMARY KEY (site_id, tag_id)
);

CREATE INDEX idx_sites_tags_tag_id ON sites_tags(tag_id);
```

### follows
User following relationships.

```sql
CREATE TABLE follows (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    actioned_site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    UNIQUE(site_id, actioned_site_id)
);

CREATE INDEX idx_follows_site_id ON follows(site_id);
CREATE INDEX idx_follows_actioned_site_id ON follows(actioned_site_id);
```

### comments
Comments on user profiles.

```sql
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    commenter_site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT false
);

CREATE INDEX idx_comments_site_id ON comments(site_id);
CREATE INDEX idx_comments_created_at ON comments(created_at DESC);
```

### comment_likes
Likes on comments.

```sql
CREATE TABLE comment_likes (
    id SERIAL PRIMARY KEY,
    comment_id INTEGER NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    UNIQUE(comment_id, site_id)
);
```

## Analytics & Statistics

### stats
Raw analytics data for page views.

```sql
CREATE TABLE stats (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    ip_address INET NOT NULL,
    path VARCHAR(500) NOT NULL,
    referrer TEXT,
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Partitioned by date for performance
CREATE INDEX idx_stats_site_created ON stats(site_id, created_at DESC);
CREATE INDEX idx_stats_created_at ON stats(created_at);
```

### daily_site_stats
Aggregated daily statistics per site.

```sql
CREATE TABLE daily_site_stats (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    views INTEGER DEFAULT 0,
    unique_visitors INTEGER DEFAULT 0,
    
    UNIQUE(site_id, date)
);

CREATE INDEX idx_daily_site_stats_date ON daily_site_stats(date DESC);
```

### stat_locations
Geographic statistics.

```sql
CREATE TABLE stat_locations (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    country VARCHAR(2),
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### stat_referrers
Referrer statistics.

```sql
CREATE TABLE stat_referrers (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    host VARCHAR(255),
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

### stat_paths
Page path statistics.

```sql
CREATE TABLE stat_paths (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    path VARCHAR(500),
    views INTEGER DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

## Moderation & Security

### reports
User reports for content moderation.

```sql
CREATE TABLE reports (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    reporting_site_id INTEGER REFERENCES sites(id) ON DELETE SET NULL,
    report_type VARCHAR(50) NOT NULL,
    message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP,
    resolved_by INTEGER REFERENCES sites(id) ON DELETE SET NULL
);

CREATE INDEX idx_reports_resolved ON reports(resolved, created_at DESC);
```

### blocks
User blocking relationships.

```sql
CREATE TABLE blocks (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    blocked_site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    
    UNIQUE(site_id, blocked_site_id)
);
```

### blocked_ips
IP address blocking for spam prevention.

```sql
CREATE TABLE blocked_ips (
    id SERIAL PRIMARY KEY,
    ip_address INET NOT NULL,
    reason VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_blocked_ips_ip ON blocked_ips(ip_address);
```

## Events & Audit Log

### events
System events and audit trail.

```sql
CREATE TABLE events (
    id SERIAL PRIMARY KEY,
    site_id INTEGER REFERENCES sites(id) ON DELETE CASCADE,
    event_type VARCHAR(100) NOT NULL,
    data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_events_site_type ON events(site_id, event_type);
CREATE INDEX idx_events_created_at ON events(created_at DESC);
CREATE INDEX idx_events_data ON events USING GIN(data);
```

## Payment & Subscription

### tips
User tips/donations.

```sql
CREATE TABLE tips (
    id SERIAL PRIMARY KEY,
    site_id INTEGER NOT NULL REFERENCES sites(id) ON DELETE CASCADE,
    tipper_site_id INTEGER REFERENCES sites(id) ON DELETE SET NULL,
    amount_cents INTEGER NOT NULL,
    stripe_charge_id VARCHAR(255),
    message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
```

## Caching

### simple_cache
Application-level caching.

```sql
CREATE TABLE simple_cache (
    id SERIAL PRIMARY KEY,
    key VARCHAR(255) UNIQUE NOT NULL,
    value TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_simple_cache_expires ON simple_cache(expires_at);
```

## Migration Strategy

### Sequel Migrations
Neocities uses Sequel migrations for schema changes:

```ruby
# Example migration: 001_create_sites.rb
Sequel.migration do
  up do
    create_table(:sites) do
      primary_key :id
      String :username, null: false, unique: true
      String :email, null: false
      String :password_hash, null: false
      DateTime :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :updated_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      
      index :username
      index :email
    end
  end
  
  down do
    drop_table(:sites)
  end
end
```

### Schema Versioning
- Migrations are numbered sequentially
- Applied automatically on application startup
- Rollback capability for safe schema changes
- Database schema version tracked in `schema_info` table

## Performance Considerations

### Indexing Strategy
- Primary keys on all tables
- Foreign key indexes for joins
- Composite indexes for common query patterns
- Partial indexes for filtered queries

### Partitioning
- `stats` table partitioned by date for performance
- Archive old data to maintain query performance
- Separate read replicas for analytics queries

### Query Optimization
- Use EXPLAIN ANALYZE for query optimization
- Implement eager loading to avoid N+1 queries
- Cache expensive aggregation queries
- Use materialized views for complex reporting

## Backup & Maintenance

### Backup Strategy
- Daily full database backups
- Continuous WAL archiving
- Point-in-time recovery capability
- Regular backup restoration testing

### Maintenance Tasks
- Regular VACUUM and ANALYZE operations
- Index maintenance and rebuilding
- Statistics updates for query planner
- Archive old log data based on retention policies