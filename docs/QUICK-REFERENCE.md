# ⚡ Quick Reference Card - Insurance Automation

**Print this page or keep it handy during setup!**

---

## 🔑 **Credentials You'll Need**

### 1. Airtable Personal Access Token
```
🔗 Get it: https://airtable.com/create/tokens
📋 Scopes needed:
   ✓ data.records:read
   ✓ data.records:write
   ✓ schema.bases:read
📌 Add your base to token access
```

### 2. Twilio
```
🔗 Get it: https://console.twilio.com
📋 You need:
   ✓ Account SID
   ✓ Auth Token
   ✓ Phone Number (+1XXXXXXXXXX)
💰 Cost: $15 trial credits + $1/month for number
```

### 3. Gmail OAuth2
```
🔗 Get it: https://console.cloud.google.com
📋 You need:
   ✓ Enable Gmail API
   ✓ Create OAuth2 Client ID
   ✓ Client ID + Client Secret
   ✓ Set redirect URI from n8n
🔐 Recommended for production
```

---

## 📊 **Airtable Table Structure**

### Table 1: Leads
```
Lead ID              Formula: RECORD_ID()
First Name           Single line text
Last Name            Single line text
Email                Email
Phone                Phone
Qualification Score  Number
Status              Single select: HOT_LEAD, QUALIFIED, POTENTIAL, DISQUALIFIED
Lead Source          Single line text
Insurance Type       Single line text
Received At          Date
```

### Table 2: Appointments
```
Appointment ID       Single line text
Lead                Link to Leads table
Appointment Date     Date/Time
Status              Single select: Scheduled, Confirmed, Completed, Cancelled
Reminders Sent      Multiple select
Agent Name          Single line text
```

### Table 3: Policies
```
Policy ID           Single line text
Policy Number       Single line text
Client              Link to Leads table
Policy Type         Single select: Life, Health, Medicare, etc.
Expiration Date     Date
Annual Premium      Currency
Renewal Status      Single select
Years as Customer   Number
```

### Table 4: Chat Sessions
```
Session ID          Single line text
User Message        Long text
Bot Response        Long text
Intent             Single line text
Timestamp          Date/Time
Lead Captured      Checkbox
```

---

## 🎯 **Webhook URLs**

After importing workflows, you'll get these webhook URLs:

```
Lead Intake:
https://your-n8n.com/webhook/lead-intake

Follow-Up Trigger:
https://your-n8n.com/webhook/follow-up-trigger

Appointment Scheduled:
https://your-n8n.com/webhook/appointment-scheduled

Lead Response:
https://your-n8n.com/webhook/lead-response

Appointment Response:
https://your-n8n.com/webhook/appointment-response

Chatbot:
https://your-n8n.com/webhook/chatbot

Lead Captured:
https://your-n8n.com/webhook/chatbot-lead-captured
```

---

## 🔧 **Nodes to Update in Each Workflow**

### Workflow 1: Lead Qualification
```
✏️ "Set Team Info" → Your agency name/phone/email
✏️ "Save to Airtable" → Your Airtable base
✏️ "Notify Team - Hot Lead" → Your email
✏️ "SMS to Qualified Lead" → Your Twilio number
```

### Workflow 2: Follow-Up Machine
```
✏️ All email nodes → Your agency email address
✏️ All SMS nodes → Your Twilio number
✏️ Update agent name in templates
```

### Workflow 3: Appointment Reminders
```
✏️ "Send Immediate Confirmation" → Your email
✏️ "Send Confirmation SMS" → Your Twilio number
✏️ "Update Appointment Status" → Your Airtable base
```

### Workflow 4: Policy Renewals
```
✏️ "Get Expiring Policies" → Your Airtable base
✏️ "Send Daily Report" → Your email
✏️ All email templates → Agent names/phone
```

### Workflow 5: Chatbot
```
✏️ "Generate Bot Response" → Agency name
✏️ "Send to Lead Qualification" → Your webhook URL
✏️ "Log Conversation" → Your Airtable base
```

### Workflow 6: ROI Tracker
```
✏️ "Get Leads (Last 30 Days)" → Your Airtable base
✏️ "Get Closed Deals" → Your Airtable base
✏️ "Send ROI Report Email" → Your email
✏️ Update cost per lead estimates
```

---

## 🧪 **Test Data Examples**

### Test Lead (POST to /webhook/lead-intake):
```json
{
  "firstName": "Sarah",
  "lastName": "Johnson",
  "email": "sarah.j@example.com",
  "phone": "+15551234567",
  "insuranceType": "Life Insurance",
  "annualIncome": 85000,
  "age": 35,
  "timeline": "immediate",
  "zipCode": "90210",
  "state": "CA",
  "leadSource": "Facebook"
}
```

### Test Appointment:
```json
{
  "appointmentId": "APT-123",
  "firstName": "Michael",
  "lastName": "Brown",
  "email": "michael.b@example.com",
  "phone": "+15559876543",
  "appointmentDate": "2025-11-20T14:00:00Z",
  "agentName": "Your Name",
  "insuranceType": "Health Insurance"
}
```

### Test Chat Message:
```json
{
  "message": "I need life insurance",
  "sessionId": "session-123",
  "email": "visitor@example.com"
}
```

---

## 📈 **Expected Metrics (First Month)**

### Week 1:
```
Leads processed: 50-100
Qualification rate: 40-50%
Follow-ups sent: 200-400 messages
No-show rate: Start tracking
```

### Week 2:
```
Leads processed: 100-200
Qualification rate: 50-60%
Conversion improvement: +10-15%
No-show reduction: -20-30%
```

### Week 3:
```
Leads processed: 150-300
Response rate: 15-20%
Closed deals: +3-5 extra
Retention: Start tracking renewals
```

### Week 4:
```
Full automation running
Time saved: 40-60 hours
Revenue impact: +15-25%
ROI data available
```

---

## ⚠️ **Common Errors & Quick Fixes**

### "Invalid API Key" (Airtable)
```
❌ Using old API key
✅ Switch to Personal Access Token
```

### "Unauthorized" (Gmail)
```
❌ Using regular password
✅ Use OAuth2 or App Password
```

### "Invalid Phone Number" (Twilio)
```
❌ Format: 5551234567
✅ Format: +15551234567
```

### "Webhook not found"
```
❌ Workflow is inactive
✅ Click "Active" toggle
```

### "Data not in Airtable"
```
❌ Wrong base ID or table name
✅ Copy exact IDs from Airtable URL
```

---

## 💡 **Pro Tips**

### Tip 1: Start Small
```
✓ Activate one workflow at a time
✓ Test with real data for 24 hours
✓ Monitor for errors
✓ Then activate next workflow
```

### Tip 2: Monitor Daily (First Week)
```
✓ Check n8n execution logs
✓ Verify emails aren't spam
✓ Confirm SMS delivery
✓ Review Airtable data
```

### Tip 3: Adjust Gradually
```
✓ Week 1: Default settings
✓ Week 2: Adjust scoring thresholds
✓ Week 3: Customize messages
✓ Week 4: Optimize timing
```

### Tip 4: Track ROI
```
Before: [Record current metrics]
After 30 days: [Compare results]
Key metrics: Close rate, no-shows, time saved
```

---

## 🚀 **Speed Run Checklist (30 Minutes)**

```
[  ] 0-5 min:   Install n8n (Docker or npm)
[  ] 5-10 min:  Create Airtable base + tables
[  ] 10-15 min: Get Twilio account + number
[  ] 15-20 min: Set up Gmail OAuth2
[  ] 20-25 min: Import all 6 workflows
[  ] 25-30 min: Update credentials in workflows
[  ] 30-35 min: Test with sample data
[  ] 35-40 min: Activate workflows
[  ] Done! ✅
```

---

## 📞 **Emergency Support**

### Workflow Not Working?
```
1. Check it's Active (toggle in top-right)
2. View execution log (click workflow run)
3. Check credentials are connected
4. Verify webhook URLs are correct
```

### Credentials Failed?
```
Airtable: Check token scopes + base access
Twilio:   Verify SID and Auth Token
Gmail:    Re-authenticate OAuth2
```

### No Data in Airtable?
```
1. Check base ID matches
2. Verify table names exact
3. Ensure credentials have write access
4. Test with manual execution
```

---

## 🎯 **Success Checklist**

After setup, you should see:

```
✅ Leads automatically scored and routed
✅ Follow-up emails/SMS sending
✅ Appointment reminders going out
✅ Renewal notifications triggered
✅ Chatbot responding to inquiries
✅ Weekly ROI reports in email
✅ Data flowing to Airtable
✅ Dashboard showing metrics
```

---

## 📚 **Key Documentation Pages**

```
Quick Start:    docs/quick-start.md
Configuration:  docs/configuration-guide.md
Compatibility:  docs/n8n-compatibility-updates.md
Main README:    README.md
Dashboard:      dashboard/index.html
```

---

**Keep this page bookmarked for quick reference during setup and troubleshooting!**

*Last updated: November 2025*
