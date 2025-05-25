# Database Backup Script - Interview Q&A Guide

## 1. Bash Scripting & Programming Questions

### Q: Walk me through your approach to error handling in this bash script.

**Answer:**
"I implemented a multi-layered error handling strategy:

1. **Set strict mode**: `set -euo pipefail` to exit on errors, undefined variables, and pipe failures
2. **Custom error handler**: A trap function that captures errors with line numbers and context
3. **Return code checking**: Explicitly check return codes for critical operations
4. **Graceful degradation**: Non-critical failures don't stop the entire process
5. **Cleanup on exit**: Signal traps ensure temporary files are cleaned up

Example implementation:
```bash
set -euo pipefail

cleanup() {
    rm -f "$TEMP_FILE" 2>/dev/null || true
    exit ${1:-1}
}

trap 'cleanup $?' ERR EXIT
trap 'echo "Interrupted"; cleanup 130' INT TERM

# Function with proper error handling
backup_database() {
    local db_name="$1"
    local backup_file="$2"
    
    if ! mysqldump --single-transaction "$db_name" > "$backup_file"; then
        log_error "Failed to backup database: $db_name"
        return 1
    fi
    
    if ! gzip "$backup_file"; then
        log_error "Failed to compress backup: $backup_file"
        return 1
    fi
    
    return 0
}
```

This approach ensures the script fails fast but gracefully, with proper logging and cleanup."

### Q: How do you handle configuration management in your script?

**Answer:**
"I use a layered configuration approach:

1. **Default values**: Hard-coded sensible defaults in the script
2. **Configuration file**: External config file for environment-specific settings
3. **Environment variables**: Override config file values
4. **Command-line arguments**: Highest priority overrides

Implementation pattern:
```bash
# Default values
DEFAULT_RETENTION_DAYS=7
DEFAULT_BACKUP_DIR="/var/backups"

# Load config file
load_config() {
    local config_file="${1:-/opt/db-backup/config/backup.conf}"
    
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    else
        log_warn "Config file not found: $config_file. Using defaults."
    fi
}

# Apply environment overrides
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-${RETENTION_DAYS:-$DEFAULT_RETENTION_DAYS}}"
BACKUP_DIR="${BACKUP_DIRECTORY:-${BACKUP_DIR:-$DEFAULT_BACKUP_DIR}}"
```

This provides flexibility while maintaining security through proper file permissions (600) on config 
files."

### Q: Explain your logging strategy.

**Answer:**
"I implemented structured logging with multiple levels and outputs:

```bash
# Logging configuration
LOG_LEVELS=("DEBUG" "INFO" "WARN" "ERROR")
CURRENT_LOG_LEVEL="INFO"

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Check if level should be logged
    if ! should_log "$level"; then
        return 0
    fi
    
    # Format: [TIMESTAMP] [LEVEL] [PID] MESSAGE
    local log_entry="[$timestamp] [$level] [$$] $message"
    
    # Output to both file and stderr for errors
    echo "$log_entry" >> "$LOG_FILE"
    
    if [[ "$level" == "ERROR" || "$level" == "WARN" ]]; then
        echo "$log_entry" >&2
    fi
}

# Convenience functions
log_info() { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }
log_warn() { log "WARN" "$@"; }
log_debug() { log "DEBUG" "$@"; }
```

Key features:
- **Structured format**: Consistent timestamp, level, PID
- **Level filtering**: Only log appropriate levels
- **Multiple outputs**: File logging with stderr for errors
- **Log rotation**: Integrated with logrotate or custom rotation
- **Performance**: Minimal overhead for disabled levels"

## 2. System Administration Questions

### Q: How would you secure this backup script in a production environment?

**Answer:**
"Security is implemented at multiple layers:

**1. File System Security:**
```bash
# Secure permissions
chmod 700 /opt/db-backup/bin/
chmod 600 /opt/db-backup/config/backup.conf
chown backup:backup /opt/db-backup/
```

**2. Database Security:**
- Dedicated backup user with minimal privileges (SELECT, LOCK TABLES, SHOW VIEW)
- Password stored in separate file with 600 permissions
- Connection over localhost or secured connections only

**3. Credential Management:**
```bash
# Store sensitive data separately
DB_PASSWORD_FILE="/opt/db-backup/config/.db_password"
if [[ -f "$DB_PASSWORD_FILE" ]]; then
    DB_PASSWORD=$(cat "$DB_PASSWORD_FILE")
else
    log_error "Password file not found"
    exit 1
fi
```

**4. AWS Security:**
- IAM roles instead of access keys when possible
- Least privilege IAM policies
- S3 bucket encryption enabled
- Secure credential storage

**5. Process Security:**
- Run as dedicated backup user (not root)
- Mask sensitive parameters in process list
- Secure temporary file handling with mktemp"

### Q: How do you handle backup rotation and storage management?

**Answer:**
"I implement a tiered retention strategy:

```bash
cleanup_old_backups() {
    local backup_dir="$1"
    
    # Daily backups - keep for 7 days
    find "$backup_dir" -name "*daily*.sql.gz" -mtime +${RETENTION_DAYS} -delete
    
    # Weekly backups - keep for 4 weeks
    find "$backup_dir" -name "*weekly*.sql.gz" -mtime +$((RETENTION_WEEKS * 7)) -delete
    
    # Monthly backups - keep for 6 months
    find "$backup_dir" -name "*monthly*.sql.gz" -mtime +$((RETENTION_MONTHS * 30)) -delete
    
    log_info "Cleanup completed for $backup_dir"
}

# Intelligent naming for different backup types
generate_backup_filename() {
    local db_name="$1"
    local backup_type="$2"  # daily, weekly, monthly
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    echo "${db_name}_${backup_type}_${timestamp}.sql.gz"
}
```

**Storage Management:**
- Monitor disk usage before backup
- Fail if insufficient space (configurable threshold)
- Compress backups (gzip, bzip2, or xz based on config)
- Move old backups to cheaper S3 storage classes
- Implement S3 lifecycle policies for automatic archival"

### Q: How would you monitor and alert on backup failures?

**Answer:**
"I implement comprehensive monitoring at multiple levels:

**1. Script-level Monitoring:**
```bash
send_notification() {
    local status="$1"
    local message="$2"
    
    # Slack notification
    if [[ -n "$SLACK_WEBHOOK_URL" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Backup $status: $message\"}" \
            "$SLACK_WEBHOOK_URL"
    fi
    
    # Email notification
    if [[ -n "$EMAIL_RECIPIENTS" ]]; then
        echo "$message" | mail -s "Backup $status" "$EMAIL_RECIPIENTS"
    fi
}

# Success/failure notifications
backup_database() {
    if perform_backup "$1"; then
        if [[ "$NOTIFICATION_ON_SUCCESS" == "true" ]]; then
            send_notification "SUCCESS" "Database $1 backed up successfully"
        fi
    else
        send_notification "FAILED" "Database $1 backup failed"
        return 1
    fi
}
```

**2. External Monitoring:**
- Cron job monitoring with tools like cronitor or healthchecks.io
- Log file monitoring with ELK stack or similar
- S3 upload verification
- Database size trend monitoring

**3. Health Checks:**
```bash
# Generate status file for external monitoring
generate_status_file() {
    local status_file="/opt/db-backup/status/last_backup.json"
    
    cat > "$status_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "status": "$1",
    "databases_backed_up": $2,
    "total_size_mb": $3,
    "duration_seconds": $4,
    "s3_upload_status": "$5"
}
EOF
}
```"

## 3. DevOps & Architecture Questions

### Q: How would you scale this backup solution for a large enterprise?

**Answer:**
"For enterprise scale, I'd implement several architectural improvements:

**1. Distributed Architecture:**
```bash
# Master-worker pattern
backup_coordinator() {
    local databases=("$@")
    local max_parallel=${MAX_PARALLEL_BACKUPS:-3}
    
    for db in "${databases[@]}"; do
        # Limit concurrent backups
        while (( $(jobs -r | wc -l) >= max_parallel )); do
            wait -n  # Wait for any job to complete
        done
        
        backup_database "$db" &
    done
    
    wait  # Wait for all backups to complete
}
```

**2. Configuration Management:**
- Centralized configuration with tools like Consul or etcd
- Database discovery through service registry
- Dynamic backup scheduling based on database size/importance

**3. Resource Management:**
```bash
# Intelligent resource allocation
calculate_backup_resources() {
    local db_size="$1"
    local available_memory=$(free -m | awk '/^Mem:/{print $7}')
    local available_disk=$(df "$BACKUP_DIR" | awk 'NR==2{print $4}')
    
    # Adjust backup strategy based on resources
    if (( db_size > available_disk / 2 )); then
        echo "streaming"  # Stream directly to S3
    else
        echo "local"      # Local backup then upload
    fi
}
```

**4. Enterprise Features:**
- Multi-region S3 replication
- Backup verification and restoration testing
- Compliance reporting and audit trails
- Integration with enterprise monitoring (Prometheus, Grafana)
- Backup encryption with enterprise key management"

### Q: How do you handle database consistency during backups?

**Answer:**
"Database consistency is critical. I implement different strategies per database type:

**MySQL:**
```bash
backup_mysql() {
    local db_name="$1"
    local backup_file="$2"
    
    # Use single-transaction for InnoDB consistency
    mysqldump \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --quick \
        --lock-tables=false \
        --master-data=2 \
        "$db_name" > "$backup_file"
}
```

**PostgreSQL:**
```bash
backup_postgresql() {
    local db_name="$1"
    local backup_file="$2"
    
    # Use pg_dump with serializable isolation
    pg_dump \
        --verbose \
        --no-owner \
        --no-privileges \
        --format=custom \
        --compress=9 \
        "$db_name" > "$backup_file"
}
```

**Key Consistency Measures:**
1. **Point-in-time consistency**: Single transaction for entire backup
2. **Application coordination**: Optional pre/post backup hooks for application quiescing
3. **Read replica backups**: Backup from read replicas to reduce primary load
4. **Verification**: Automatic backup integrity checks"

### Q: How would you implement disaster recovery with this script?

**Answer:**
"Disaster recovery requires multiple components:

**1. Geographic Distribution:**
```bash
# Multi-region S3 uploads
upload_to_multiple_regions() {
    local backup_file="$1"
    local regions=("us-east-1" "us-west-2" "eu-west-1")
    
    for region in "${regions[@]}"; do
        aws s3 cp "$backup_file" \
            "s3://${S3_BUCKET}-${region}/${S3_PREFIX}/" \
            --region "$region" &
    done
    
    wait  # Wait for all uploads
}
```

**2. Recovery Testing:**
```bash
test_backup_recovery() {
    local backup_file="$1"
    local test_db="test_recovery_$(date +%s)"
    
    # Create test database and restore
    mysql -e "CREATE DATABASE $test_db"
    
    if zcat "$backup_file" | mysql "$test_db"; then
        log_info "Backup verification successful: $backup_file"
        mysql -e "DROP DATABASE $test_db"
        return 0
    else
        log_error "Backup verification failed: $backup_file"
        return 1
    fi
}
```

**3. RTO/RPO Management:**
- Configurable backup frequency based on RPO requirements
- Fast restore procedures with parallel processing
- Database-specific optimization for faster recovery
- Documentation and runbooks for disaster scenarios

**4. Monitoring and Alerting:**
- Cross-region backup verification
- Recovery time testing and reporting
- Compliance reporting for audit requirements"

## 4. Troubleshooting & Problem-Solving Questions

### Q: A backup is taking much longer than usual. How would you troubleshoot this?

**Answer:**
"I'd follow a systematic troubleshooting approach:

**1. Immediate Investigation:**
```bash
# Check current backup process
ps aux | grep -E "(mysqldump|pg_dump|mongodump)"

# Monitor system resources
iostat -x 1    # Disk I/O
top -p $(pgrep mysqldump)  # Process resources
iotop          # I/O by process

# Check database locks (MySQL)
mysql -e "SHOW PROCESSLIST; SHOW ENGINE INNODB STATUS\\G"
```

**2. Performance Analysis:**
```bash
# Add timing to backup functions
backup_with_timing() {
    local start_time=$(date +%s)
    local db_name="$1"
    
    log_info "Starting backup of $db_name"
    
    if backup_database "$db_name"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_info "Backup of $db_name completed in ${duration}s"
        
        # Alert if backup takes longer than threshold
        if (( duration > BACKUP_TIMEOUT_THRESHOLD )); then
            send_alert "Long backup detected: ${db_name} took ${duration}s"
        fi
    fi
}
```

**3. Common Causes & Solutions:**
- **Large table locks**: Switch to `--single-transaction` for InnoDB
- **High database load**: Schedule backups during low-usage periods
- **Network issues**: Check S3 upload speeds, implement retry logic
- **Disk I/O contention**: Implement backup scheduling to avoid peak times
- **Database growth**: Implement incremental backup strategies

**4. Preventive Measures:**
- Monitor backup duration trends
- Implement backup size and time alerts
- Regular performance baseline reviews"

### Q: How would you handle a situation where backups are failing due to insufficient disk space?

**Answer:**
"I'd implement both immediate fixes and long-term solutions:

**1. Immediate Response:**
```bash
check_disk_space() {
    local backup_dir="$1"
    local required_space="$2"  # in MB
    
    local available_space=$(df "$backup_dir" | awk 'NR==2{print $4}')
    local available_mb=$((available_space / 1024))
    
    if (( available_mb < required_space )); then
        log_error "Insufficient disk space: ${available_mb}MB available, ${required_space}MB required"
        
        # Emergency cleanup
        emergency_cleanup "$backup_dir"
        
        # Recheck after cleanup
        available_space=$(df "$backup_dir" | awk 'NR==2{print $4}')
        available_mb=$((available_space / 1024))
        
        if (( available_mb < required_space )); then
            send_alert "CRITICAL: Still insufficient disk space after cleanup"
            return 1
        fi
    fi
    
    return 0
}

emergency_cleanup() {
    local backup_dir="$1"
    
    # Remove backups older than emergency threshold
    find "$backup_dir" -name "*.sql.gz" -mtime +2 -delete
    
    # Remove temporary files
    find "$backup_dir" -name "*.tmp" -delete
    
    log_info "Emergency cleanup completed"
}
```

**2. Predictive Monitoring:**
```bash
predict_space_requirements() {
    local db_name="$1"
    
    # Get database size
    local db_size=$(mysql -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'DB Size in 
MB' FROM information_schema.tables WHERE table_schema='$db_name';" -sN)
    
    # Estimate compressed backup size (typically 20-30% of original)
    local estimated_backup_size=$((db_size * 30 / 100))
    
    echo "$estimated_backup_size"
}
```

**3. Long-term Solutions:**
- Implement streaming backups directly to S3 for large databases
- Set up automatic disk space monitoring with proactive alerts
- Implement tiered storage with faster cleanup of old backups
- Configure backup compression optimization
- Consider backup sharding for very large databases"

## 5. Best Practices & Architecture Questions

### Q: What would you do differently if you had to implement this in a cloud-native environment?

**Answer:**
"For cloud-native deployment, I'd redesign several components:

**1. Containerization:**
```dockerfile
FROM alpine:latest

RUN apk add --no-cache \
    mysql-client \
    postgresql-client \
    mongodb-tools \
    aws-cli \
    bash \
    curl

COPY db_backup.sh /usr/local/bin/
COPY config/ /opt/db-backup/config/

USER 1000:1000
ENTRYPOINT ["/usr/local/bin/db_backup.sh"]
```

**2. Kubernetes Implementation:**
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-backup
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: db-backup
            image: company/db-backup:latest
            env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: password
            volumeMounts:
            - name: config
              mountPath: /opt/db-backup/config
          volumes:
          - name: config
            configMap:
              name: backup-config
          restartPolicy: OnFailure
```

**3. Cloud-Native Features:**
- **Service discovery**: Use Kubernetes services or cloud service discovery
- **Secret management**: Kubernetes secrets or cloud secret managers (AWS Secrets Manager)
- **Monitoring**: Prometheus metrics and Grafana dashboards
- **Logging**: Structured logging to stdout for container log aggregation
- **Storage**: Cloud-native storage solutions (EFS, EBS) with automatic scaling

**4. Serverless Alternative:**
- AWS Lambda for smaller databases
- Step Functions for orchestrating complex backup workflows
- CloudWatch Events for scheduling
- SNS/SQS for notification and queueing"

### Q: How would you ensure this script is maintainable and testable?

**Answer:**
"Maintainability and testability are built into the design:

**1. Modular Architecture:**
```bash
# Separate concerns into functions
source_modules() {
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    source "$script_dir/lib/database.sh"
    source "$script_dir/lib/s3.sh"
    source "$script_dir/lib/logging.sh"
    source "$script_dir/lib/notifications.sh"
}

# Each module has a single responsibility
# database.sh - all database operations
# s3.sh - all S3 operations
# logging.sh - logging functionality
# notifications.sh - alert and notification handling
```

**2. Unit Testing Framework:**
```bash
# test_backup.sh
#!/bin/bash

source "./test_framework.sh"
source "./db_backup.sh"

test_backup_filename_generation() {
    local result=$(generate_backup_filename "testdb" "daily")
    assert_matches "$result" "testdb_daily_[0-9]{8}_[0-9]{6}\.sql\.gz"
}

test_config_validation() {
    # Test with invalid config
    DB_TYPE="invalid_type"
    assert_fails validate_config
    
    # Test with valid config
    DB_TYPE="mysql"
    assert_succeeds validate_config
}

run_tests() {
    test_backup_filename_generation
    test_config_validation
    # ... more tests
}

run_tests
```

**3. Integration Testing:**
```bash
# integration_test.sh
setup_test_environment() {
    # Create test database
    mysql -e "CREATE DATABASE test_backup_db"
    mysql test_backup_db < test_data.sql
    
    # Set test configuration
    export BACKUP_DIR="/tmp/test_backups"
    export S3_BUCKET="test-backup-bucket"
}

test_full_backup_cycle() {
    setup_test_environment
    
    # Run backup
    ./db_backup.sh -d test_backup_db
    
    # Verify backup file exists
    assert_file_exists "/tmp/test_backups/test_backup_db_*.sql.gz"
    
    # Verify S3 upload
    aws s3 ls "s3://test-backup-bucket/" | grep test_backup_db
    
    cleanup_test_environment
}
```

**4. Documentation and Standards:**
- Comprehensive inline documentation
- Function documentation with parameters and return values
- README with usage examples and troubleshooting
- Code style consistency with shellcheck integration
- Version control with meaningful commit messages"

This comprehensive Q&A guide covers the most common interview questions you'll encounter when discussing 
automation scripts, system administration, and DevOps practices. Each answer demonstrates deep technical 
knowledge while showing practical problem-solving skills.
