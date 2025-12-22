# MediCore PostgreSQL Database Setup

## 📋 Overview

This directory contains the PostgreSQL database schema for the MediCore medical management system. The schema has been migrated from SQLite to PostgreSQL for improved performance, scalability, and multi-user support.

## 📊 Database Schema

**Total Tables:** 18 (14 core + 4 system)  
**Total Fields:** ~220 fields  
**Total Indexes:** 60+ indexes  

### Core Tables (14)

1. **users** - User accounts (6 fields + metadata)
2. **templates** - User role templates (4 fields + metadata)
3. **rooms** - Consultation rooms (2 fields + metadata)
4. **patients** - Patient master data (12 fields)
5. **visits** - Ophthalmology consultation records (54 fields!)
6. **ordonnances** - Medical documents (23 fields)
7. **medications** - Medication templates (8 fields)
8. **medical_acts** - Medical procedures/fees (6 fields)
9. **payments** - Payment tracking (14 fields)
10. **message_templates** - Quick message templates (5 fields)
11. **messages** - Doctor-nurse communication (12 fields)
12. **waiting_patients** - Patient queue per room (19 fields)
13. **appointments** - Scheduled appointments (13 fields)
14. **surgery_plans** - Surgery scheduling (21 fields)

### System Tables (4)

15. **sessions** - User session management
16. **audit_log** - Audit trail for compliance
17. **nurse_preferences** - Nurse room assignments
18. **app_metadata** - Application metadata

## 🚀 Installation

### Prerequisites

1. **PostgreSQL 14+**
   ```bash
   # macOS
   brew install postgresql@14
   brew services start postgresql@14
   
   # Ubuntu/Debian
   sudo apt update
   sudo apt install postgresql-14
   sudo systemctl start postgresql
   
   # Windows
   # Download from https://www.postgresql.org/download/windows/
   ```

2. **Python 3.7+** (for data migration)
   ```bash
   pip3 install psycopg2-binary
   ```

### Step 1: Create Database

```bash
# Create PostgreSQL user
sudo -u postgres createuser -P medicore
# Enter password: medicore

# Create database
sudo -u postgres createdb -O medicore medicore_db
```

### Step 2: Run Schema Migration

```bash
cd medicore_server/scripts
chmod +x migrate.sh
./migrate.sh
```

Or manually:
```bash
psql -U medicore -d medicore_db -f ../database/schema_postgresql.sql
```

### Step 3: Import Existing SQLite Data (Optional)

If you have an existing SQLite database:

```bash
cd medicore_server/scripts
python3 import_from_sqlite.py /path/to/medicore.db
```

## 🔧 Configuration

### Environment Variables

```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=medicore
export DB_PASSWORD=medicore
export DB_NAME=medicore_db
export DB_SSLMODE=disable
```

### Connection String

```
postgresql://medicore:medicore@localhost:5432/medicore_db?sslmode=disable
```

## 📝 Verification

### Check Installation

```bash
# Connect to database
psql -U medicore -d medicore_db

# List tables
\dt

# Check schema version
SELECT value_text FROM app_metadata WHERE key = 'schema_version';

# Count records
SELECT 
    table_name, 
    (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as columns
FROM information_schema.tables t
WHERE table_schema = 'public'
ORDER BY table_name;
```

### Expected Output

```
 table_name         | columns
--------------------+---------
 app_metadata       |       3
 appointments       |      13
 audit_log          |       9
 medical_acts       |       6
 medications        |       8
 message_templates  |       5
 messages           |      12
 nurse_preferences  |       6
 ordonnances        |      23
 patients           |      12
 payments           |      14
 rooms              |       4
 sessions           |       7
 surgery_plans      |      21
 templates          |       8
 users              |      12
 visits             |      54
 waiting_patients   |      19
(18 rows)
```

## 🔍 Key Features

### Performance Optimizations

- **60+ Indexes** for fast queries
- **Full-text search** on patient names using `pg_trgm`
- **Connection pooling** (50 max connections, 10 idle)
- **Prepared statements** for SQL injection protection

### Data Integrity

- **Foreign key constraints** on all relationships
- **Soft deletes** (`deleted_at` timestamp)
- **Audit logging** for compliance
- **Auto-update timestamps** via triggers

### Concurrency

- **MVCC** (Multi-Version Concurrency Control)
- **Row-level locking** for updates
- **Transaction support** for atomic operations
- **No blocking reads**

## 🔐 Security

### Best Practices

1. **Never commit passwords** - use environment variables
2. **Enable SSL** in production: `sslmode=require`
3. **Firewall** - allow only specific IPs to PostgreSQL port (5432)
4. **Strong passwords** - use 20+ character passwords
5. **Regular backups** - automated daily backups

### Production Settings

```sql
-- Create read-only user for reports
CREATE USER medicore_readonly WITH PASSWORD 'strong_password';
GRANT CONNECT ON DATABASE medicore_db TO medicore_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO medicore_readonly;

-- Backup user
CREATE USER medicore_backup WITH PASSWORD 'strong_password';
GRANT CONNECT ON DATABASE medicore_db TO medicore_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO medicore_backup;
```

## 📦 Backup & Restore

### Automated Daily Backup

```bash
#!/bin/bash
# Add to cron: 0 2 * * * /path/to/backup.sh

BACKUP_DIR="/var/backups/medicore"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/medicore_$DATE.sql.gz"

mkdir -p "$BACKUP_DIR"

pg_dump -U medicore -d medicore_db | gzip > "$BACKUP_FILE"

# Keep only last 30 days
find "$BACKUP_DIR" -name "medicore_*.sql.gz" -mtime +30 -delete

echo "Backup created: $BACKUP_FILE"
```

### Manual Backup

```bash
# Full backup
pg_dump -U medicore -d medicore_db > medicore_backup.sql

# Compressed backup
pg_dump -U medicore -d medicore_db | gzip > medicore_backup.sql.gz

# Custom format (best for large databases)
pg_dump -U medicore -d medicore_db -Fc > medicore_backup.dump
```

### Restore

```bash
# From SQL file
psql -U medicore -d medicore_db < medicore_backup.sql

# From compressed
gunzip -c medicore_backup.sql.gz | psql -U medicore -d medicore_db

# From custom format
pg_restore -U medicore -d medicore_db medicore_backup.dump
```

## 🐛 Troubleshooting

### Connection Issues

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Check port is listening
sudo netstat -tlnp | grep 5432

# Test connection
psql -U medicore -h localhost -d medicore_db -c "SELECT 1;"
```

### Performance Issues

```sql
-- Check slow queries
SELECT 
    query, 
    calls, 
    total_time, 
    mean_time 
FROM pg_stat_statements 
ORDER BY mean_time DESC 
LIMIT 10;

-- Check table sizes
SELECT 
    relname AS table_name,
    pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### Reset Database

```bash
# WARNING: This will delete all data!
psql -U postgres -c "DROP DATABASE medicore_db;"
psql -U postgres -c "CREATE DATABASE medicore_db OWNER medicore;"
psql -U medicore -d medicore_db -f schema_postgresql.sql
```

## 📚 Migration Notes

### Changes from SQLite

1. **Data Types**
   - SQLite `INTEGER` → PostgreSQL `INTEGER` or `SERIAL`
   - SQLite `TEXT` → PostgreSQL `TEXT` or `VARCHAR(n)`
   - SQLite `REAL` → PostgreSQL `DECIMAL(10,2)`
   - SQLite `TIMESTAMP` → PostgreSQL `TIMESTAMP WITH TIME ZONE`

2. **Auto-Increment**
   - SQLite `AUTOINCREMENT` → PostgreSQL `SERIAL` or `BIGSERIAL`
   - Manual sequence management → Automatic `SEQUENCE`

3. **Triggers**
   - Added automatic `updated_at` triggers
   - No manual timestamp management needed

4. **Indexes**
   - 60+ indexes created for optimal performance
   - Full-text search indexes for patient names
   - Foreign key indexes automatically created

5. **Constraints**
   - All foreign keys properly defined
   - CHECK constraints added where appropriate
   - UNIQUE constraints preserved

## 📞 Support

For issues or questions:
- Check the troubleshooting section above
- Review PostgreSQL logs: `/var/log/postgresql/`
- Contact: support@medicore.local

## 📄 License

MediCore Medical Management System - Proprietary
