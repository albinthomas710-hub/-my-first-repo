# 🛡️ Production Best Practices for Insurance Automation Suite

**Making Your Automation System Bulletproof**

This guide covers critical production best practices based on official n8n documentation and real-world deployments.

---

## 🚨 Critical: Error Handling

### 1. Central Error Handler (MUST HAVE)

**We've included**: `00-error-handler-central.json`

This workflow:
- ✅ Catches ALL errors from ALL workflows
- ✅ Categorizes errors (CONNECTION, AUTH, RATE_LIMIT, etc.)
- ✅ Determines severity (CRITICAL, HIGH, MEDIUM, LOW)
- ✅ Alerts via Telegram/Slack/Email for critical errors
- ✅ Logs to database for analysis
- ✅ Logs to Google Sheets for team visibility
- ✅ Attempts auto-recovery for recoverable errors

**Setup Instructions:**

1. **Import the error handler workflow first**
2. **Get the workflow ID** (from URL: `/workflow/12345` → ID is `12345`)
3. **Configure each workflow** to use this error handler:
   - Open each workflow
   - Click **Workflow Settings** (gear icon)
   - Set **Error Workflow** → Select "Central Error Handler"
   - Save

4. **Create error_logs table**:
```sql
CREATE TABLE error_logs (
    id SERIAL PRIMARY KEY,
    workflow_id VARCHAR(255),
    workflow_name VARCHAR(255),
    execution_id VARCHAR(255),
    node_name VARCHAR(255),
    node_type VARCHAR(255),
    error_message TEXT,
    error_stack TEXT,
    error_category VARCHAR(50),
    severity VARCHAR(20),
    suggested_action TEXT,
    auto_recoverable BOOLEAN,
    input_data JSONB,
    resolved BOOLEAN DEFAULT false,
    resolved_at TIMESTAMP,
    resolved_by VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_error_logs_severity ON error_logs(severity);
CREATE INDEX idx_error_logs_category ON error_logs(error_category);
CREATE INDEX idx_error_logs_workflow ON error_logs(workflow_name);
CREATE INDEX idx_error_logs_created ON error_logs(created_at DESC);
```

### 2. Node-Level Retry Configuration

**For EVERY external API call node**, configure retry settings:

**Right-click node → Settings → "Retry On Fail"**

**Recommended Settings:**

| Node Type | Max Tries | Wait Time | Wait Between |
|-----------|-----------|-----------|--------------|
| OpenAI | 3 | 5 sec | Fixed |
| Twilio | 3 | 3 sec | Fixed |
| SMTP Email | 5 | 5 sec | Fixed |
| PostgreSQL | 3 | 2 sec | Fixed |
| HTTP Request (external APIs) | 4 | 5 sec | Exponential |
| Slack/Telegram | 3 | 3 sec | Fixed |

**How to set:**
1. Click on any node with API call
2. Settings tab → Retry On Fail
3. Set Max Tries and Wait Between Tries
4. Choose Time Between Tries (Fixed or Exponential)

### 3. Continue On Fail (Use Carefully)

For **non-critical notifications** (like Slack messages), enable "Continue On Fail":

**When to use:**
- ✅ Slack/Telegram notifications (don't fail workflow if Slack is down)
- ✅ Optional integrations
- ✅ Logging to non-critical systems

**When NOT to use:**
- ❌ Database writes (leads, appointments, etc.)
- ❌ SMS/Email to clients
- ❌ Payment processing
- ❌ Any data that must be saved

**How to enable:**
- Right-click node → Settings → "Continue On Fail" → Toggle ON

---

## 🔐 Security Best Practices

### 1. Webhook Authentication (CRITICAL)

**NEVER leave webhooks unauthenticated in production!**

**For each webhook node:**

1. **Click on webhook node**
2. **Authentication** → Select method:

**Recommended: Header Auth**
```
Header Name: X-Auth-Token
Header Value: [Generate 32+ character random string]
```

Generate secure token:
```bash
# Linux/Mac
openssl rand -hex 32

# Or use online generator:
# https://www.random.org/strings/
```

**How clients call your webhook:**
```bash
curl -X POST https://your-n8n.com/webhook/new-lead \
  -H "X-Auth-Token: your-secure-token-here" \
  -H "Content-Type: application/json" \
  -d '{"first_name": "John", ...}'
```

**Alternative: Basic Auth**
- Username: `insurance_api`
- Password: [Strong password]

### 2. Credential Management

**DO:**
- ✅ Use n8n's built-in credential system
- ✅ Store ALL sensitive data in credentials (never in workflows)
- ✅ Use environment variables for configuration
- ✅ Rotate API keys every 90 days
- ✅ Use separate credentials for dev/prod

**DON'T:**
- ❌ Hardcode API keys in workflows
- ❌ Put passwords in node parameters
- ❌ Share credentials between environments
- ❌ Use default/weak passwords

### 3. Database Security

**Connection String:**
```
# Good (with SSL)
postgresql://user:pass@host:5432/db?ssl=true

# Bad (no SSL)
postgresql://user:pass@host:5432/db
```

**Best Practices:**
- ✅ Enable SSL/TLS for database connections
- ✅ Use database user with minimum required permissions
- ✅ Whitelist n8n server IP in database firewall
- ✅ Regular backups (automated daily)
- ✅ Encrypt backups

### 4. API Key Rotation

**Schedule for rotation:**
- OpenAI: Every 90 days
- Twilio: Every 90 days
- SMTP: Every 180 days
- CRM: Every 90 days

**Process:**
1. Generate new key in service
2. Update n8n credential
3. Test workflow execution
4. Revoke old key after 24 hours

---

## 📊 Monitoring & Observability

### 1. Daily Health Checks

**Create a monitoring dashboard:**

```sql
-- Daily Error Summary
SELECT
    DATE(created_at) as error_date,
    severity,
    error_category,
    COUNT(*) as error_count
FROM error_logs
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY error_date, severity, error_category
ORDER BY error_date DESC, error_count DESC;

-- Workflow Success Rate (Last 7 Days)
SELECT
    workflow_name,
    COUNT(*) FILTER (WHERE status = 'success') as successful,
    COUNT(*) FILTER (WHERE status = 'error') as failed,
    COUNT(*) as total,
    ROUND(COUNT(*) FILTER (WHERE status = 'success')::NUMERIC /
          NULLIF(COUNT(*), 0) * 100, 2) as success_rate
FROM workflow_executions
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY workflow_name
ORDER BY success_rate ASC;

-- Critical Errors Needing Attention
SELECT *
FROM error_logs
WHERE severity IN ('CRITICAL', 'HIGH')
  AND resolved = false
ORDER BY created_at DESC
LIMIT 20;
```

### 2. Execution History

**n8n retains execution history - configure retention:**

**Settings → Execution Data**
- Save successful executions: **7 days**
- Save failed executions: **30 days**
- Save manual executions: **90 days**

This saves database space while keeping error history for debugging.

### 3. Performance Monitoring

**Track these metrics weekly:**

| Metric | Target | Red Flag |
|--------|--------|----------|
| Average execution time | < 30 sec | > 60 sec |
| Error rate | < 2% | > 5% |
| Webhook response time | < 3 sec | > 10 sec |
| Database query time | < 500ms | > 2 sec |
| OpenAI API latency | < 5 sec | > 15 sec |

**Query for slow executions:**
```sql
SELECT
    workflow_name,
    AVG(execution_time_ms) as avg_time_ms,
    MAX(execution_time_ms) as max_time_ms
FROM workflow_executions
WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY workflow_name
HAVING AVG(execution_time_ms) > 30000
ORDER BY avg_time_ms DESC;
```

---

## 🚀 Performance Optimization

### 1. Database Connection Pooling

**In PostgreSQL credential settings:**
- Max connections: **10** (for n8n instance)
- Connection timeout: **30 seconds**

### 2. Batch Processing

**For workflows processing multiple items:**

**Use "Split In Batches" node:**
- Batch size: **10-50** items
- Prevents memory issues
- Reduces API rate limit hits

**Example:**
```
Get 1000 leads → Split In Batches (50) → Process → Loop
```

### 3. Caching Strategy

**For frequently accessed data:**

**Use "Set" node + "Memory" storage:**
- Cache lead qualification scores
- Cache quote templates
- Cache agent availability

**Example:**
```
Check cache → If not found → Fetch from DB → Cache for 1 hour
```

### 4. Rate Limit Handling

**OpenAI Rate Limits:**
- GPT-4o: 10,000 TPM (tokens per minute)
- GPT-4o-mini: 30,000 TPM

**Best practice:**
- Add "Wait" node between OpenAI calls (1-2 sec)
- Use "Rate Limit" node for batch operations
- Implement exponential backoff for 429 errors

---

## 🔄 Deployment Strategy

### 1. Version Control

**Set up Git for your workflows:**

```bash
# Export all workflows
cd ~/n8n-workflows
n8n export:workflow --all --output=./workflows/

# Commit
git add .
git commit -m "Update: Enhanced error handling in lead qualification"
git push origin main
```

**Best practices:**
- Commit after every significant change
- Use descriptive commit messages
- Tag releases: `v1.0.0`, `v1.1.0`
- Keep dev/prod branches separate

### 2. Testing Before Production

**Always test in a staging environment:**

1. **Clone workflow**
2. **Rename to "[TEST] Original Name"**
3. **Change webhook URLs to test endpoints**
4. **Test with sample data**
5. **Verify error handling**
6. **Check all integrations**
7. **Monitor for 24 hours**
8. **Then deploy to production**

### 3. Gradual Rollout

**When deploying major changes:**

Day 1: 10% of traffic
Day 2-3: 25% of traffic
Day 4-5: 50% of traffic
Day 6-7: 100% of traffic

**Use workflow versioning:**
- Keep old workflow active
- Activate new workflow
- Route % of traffic to new workflow
- Monitor error rates
- Gradually increase %

### 4. Rollback Plan

**Always have a rollback plan:**

1. **Keep old workflow ID documented**
2. **Can switch back instantly:**
   - Deactivate new workflow
   - Activate old workflow
   - Update webhook URLs (if changed)

3. **Recovery time: < 5 minutes**

---

## 📈 Scalability Considerations

### 1. When to Scale

**Scale when you hit these limits:**

| Metric | Single Instance | Need to Scale |
|--------|-----------------|---------------|
| Leads/day | < 500 | > 1,000 |
| Workflows | < 50 | > 100 |
| Executions/day | < 10,000 | > 25,000 |
| Database size | < 10 GB | > 50 GB |

### 2. Scaling Options

**Option 1: Vertical Scaling (Easier)**
- Upgrade server: 2 CPU → 4 CPU
- Increase RAM: 4 GB → 8 GB
- Cost: $20-50/month more

**Option 2: Horizontal Scaling (Better)**
- Multiple n8n instances
- Load balancer
- Shared PostgreSQL
- Redis for queue management

**Option 3: n8n Cloud (Easiest)**
- Managed scaling
- High availability
- Built-in monitoring
- Cost: $50-200/month

### 3. Database Optimization

**As data grows:**

**Partition large tables:**
```sql
-- Partition leads table by month
CREATE TABLE leads_2025_01 PARTITION OF leads
FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

CREATE TABLE leads_2025_02 PARTITION OF leads
FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');
```

**Archive old data:**
```sql
-- Archive leads older than 2 years
INSERT INTO leads_archive
SELECT * FROM leads
WHERE created_at < NOW() - INTERVAL '2 years';

DELETE FROM leads
WHERE created_at < NOW() - INTERVAL '2 years';
```

**Optimize indexes:**
```sql
-- Rebuild indexes monthly
REINDEX TABLE leads;
VACUUM ANALYZE leads;
```

---

## 🔍 Debugging Best Practices

### 1. Enable Debug Mode

**For troubleshooting:**

**Workflow Settings → Execution Data**
- ✅ Save execution progress
- ✅ Save manual executions

This shows data between each node.

### 2. Use "Set" Nodes for Debugging

**Insert "Set" nodes to inspect data:**

```javascript
// Debug node - see what data looks like
return {
  json: {
    debug_data: $input.first().json,
    data_type: typeof $input.first().json,
    keys: Object.keys($input.first().json)
  }
};
```

### 3. Test with Manual Executions

**Never test with production data!**

Use "Execute Workflow" button with test data:
```json
{
  "first_name": "Test",
  "last_name": "User",
  "email": "test@example.com",
  "phone": "+10000000000"
}
```

### 4. Check Execution Logs

**For failed executions:**
1. Go to **Executions** tab
2. Filter by "Error"
3. Click on failed execution
4. Expand node to see error details
5. Check input/output data

---

## 🎯 Production Checklist

### Before Going Live:

- [ ] ✅ Error handler workflow configured for ALL workflows
- [ ] ✅ All webhooks have authentication enabled
- [ ] ✅ Database has SSL enabled
- [ ] ✅ All credentials use strong passwords
- [ ] ✅ Retry logic configured on all external API nodes
- [ ] ✅ Test environment deployed and working
- [ ] ✅ Monitoring dashboard created
- [ ] ✅ Alert channels configured (Telegram/Slack/Email)
- [ ] ✅ Backup strategy implemented (automated daily)
- [ ] ✅ Rollback plan documented
- [ ] ✅ Team trained on error response procedures
- [ ] ✅ Rate limiting configured for APIs
- [ ] ✅ Environment variables set correctly
- [ ] ✅ Credentials rotated from defaults
- [ ] ✅ Performance baseline established
- [ ] ✅ Documentation updated
- [ ] ✅ Tested with real (non-production) data
- [ ] ✅ Verified email/SMS delivery
- [ ] ✅ Confirmed database writes working
- [ ] ✅ Checked all integrations (CRM, calendar, etc.)
- [ ] ✅ Load tested with expected volume

### Weekly Maintenance:

- [ ] Review error logs
- [ ] Check performance metrics
- [ ] Verify backup completion
- [ ] Update documentation if workflows changed
- [ ] Review and resolve open errors

### Monthly Maintenance:

- [ ] Archive old execution data
- [ ] Optimize database (VACUUM, REINDEX)
- [ ] Review and update retry settings
- [ ] Check for n8n updates
- [ ] Rotate test credentials

### Quarterly Maintenance:

- [ ] Rotate ALL API keys
- [ ] Review and update error handling logic
- [ ] Performance audit
- [ ] Security audit
- [ ] Disaster recovery test
- [ ] Update documentation

---

## 🆘 Emergency Response Procedures

### Scenario 1: Total System Failure

**If n8n instance crashes:**

1. **Immediate (0-5 min):**
   - Check server status
   - Restart n8n service: `pm2 restart n8n` or `docker restart n8n`
   - Check logs: `pm2 logs n8n` or `docker logs n8n`

2. **If restart fails (5-15 min):**
   - Check database connection
   - Check disk space: `df -h`
   - Check memory: `free -h`
   - Review error logs

3. **Communication (within 30 min):**
   - Notify team via Slack
   - Update status page if you have one
   - Estimate resolution time

### Scenario 2: Database Connection Lost

**Symptoms:** All workflows failing with "ECONNREFUSED"

1. **Check database:**
   ```bash
   psql -h hostname -U username -d database
   ```

2. **If database is up:**
   - Verify n8n credentials
   - Check firewall rules
   - Verify SSL settings

3. **If database is down:**
   - Contact database provider
   - Restore from backup if needed

### Scenario 3: API Rate Limits Hit

**Symptoms:** OpenAI/Twilio failures with "429" errors

1. **Immediate:**
   - Pause high-volume workflows
   - Let rate limit reset (usually 1 hour)

2. **Short-term:**
   - Add delays between API calls
   - Implement request queuing
   - Upgrade API tier if available

3. **Long-term:**
   - Optimize prompts to use fewer tokens
   - Cache responses where possible
   - Consider alternative providers

### Scenario 4: Mass Lead Data Loss

**Symptoms:** Leads in database but not processed

1. **Stop writes immediately**
2. **Restore from most recent backup**
3. **Re-run workflows for missed period**
4. **Investigate root cause**
5. **Document incident**

---

## 📚 Additional Resources

- [n8n Error Handling Docs](https://docs.n8n.io/flow-logic/error-handling/)
- [n8n Security Best Practices](https://docs.n8n.io/hosting/security/)
- [n8n Performance Optimization](https://docs.n8n.io/hosting/scaling/)
- [PostgreSQL Performance Tuning](https://www.postgresql.org/docs/current/performance-tips.html)

---

**Remember:** A production system is only as good as its error handling. Take the time to set this up correctly, and you'll sleep better at night! 😴

**The difference between amateur and professional automation:**
- **Amateur**: "It works on my machine!"
- **Professional**: "It works, has error handling, monitoring, backups, and a rollback plan."

Be a professional. Your clients (and your future self) will thank you. 🚀
