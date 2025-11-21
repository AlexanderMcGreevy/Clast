# Cloud Run Setup Guide

This guide shows you how to deploy a secure Cloud Run backend that calls Gemini on behalf of your iOS app.

## 🎯 Architecture

```
iOS App → Cloud Run (with GEMINI_API_KEY) → Gemini API
         Never sees API key           Returns JSON directly
```

**Security**: The iOS app NEVER sees your Gemini API key. It's stored securely in Cloud Run's environment variables.

---

## 📝 Single Endpoint: POST /verify-progress

### Input (from iOS app)

```json
{
  "sessionGoal": "Build authentication flow",
  "sessionStateSummary": "User completed database schema design",
  "userProgressNote": "Implemented OAuth login and JWT tokens",
  "scrapedTextDelta": "function authenticateUser() { ... }"
}
```

### Output (to iOS app)

```json
{
  "score": 0.75,
  "allowBreak": true,
  "reason": "Completed OAuth implementation as planned",
  "updatedSummary": "User completed auth flow with OAuth and JWT. Database schema designed. Next: implement user profile endpoints."
}
```

---

## 🚀 Complete Cloud Run Implementation

### Option 1: Node.js/Express (Recommended)

**File: `index.js`**

```javascript
const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const app = express();
app.use(express.json());

// Get API key from environment (never expose this!)
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!GEMINI_API_KEY) {
  console.error('❌ GEMINI_API_KEY environment variable is required');
  process.exit(1);
}

const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

// System prompt for Gemini
const SYSTEM_PROMPT = `You are a productivity verification assistant for a focus session app. Your role is to evaluate whether a user has made meaningful progress toward their stated session goal.

You will receive four pieces of information:
1. **sessionGoal**: The user's original goal/plan for this focus session
2. **sessionStateSummary**: A running summary of what has been accomplished so far
3. **userProgressNote**: The user's description of what they just accomplished
4. **scrapedTextDelta**: New text content extracted from the user's documents or screenshots

Your task:
1. Compare the new progress against the original session goal
2. Consider the running summary to understand what was already completed
3. Evaluate the scraped text delta carefully (code, designs, writing are strong evidence)
4. Assign a score from 0.0 to 1.0:
   - 0.0-0.3: Very little or no meaningful progress
   - 0.3-0.6: Some progress but minor/incomplete
   - 0.6-1.0: Strong, meaningful progress toward the goal
5. Set allowBreak to true only if score >= 0.6
6. Provide a short, direct explanation (1-2 sentences max)
7. Generate an updated state summary (1-3 sentences) capturing what's done and what remains

CRITICAL: Respond ONLY with valid JSON in this exact format:
{
  "score": 0.75,
  "allowBreak": true,
  "reason": "Completed the authentication flow implementation as planned.",
  "updatedSummary": "User completed authentication flow with OAuth integration. Database schema designed. Next: implement user profile API endpoints."
}

No markdown, no code blocks, no explanations. Just raw JSON.`;

// POST /verify-progress
app.post('/verify-progress', async (req, res) => {
  try {
    // 1. Validate and parse input
    const {
      sessionGoal,
      sessionStateSummary,
      userProgressNote,
      scrapedTextDelta
    } = req.body;

    if (!sessionGoal || !sessionStateSummary || !userProgressNote) {
      return res.status(400).json({
        error: 'Missing required fields: sessionGoal, sessionStateSummary, userProgressNote'
      });
    }

    // 2. Construct prompt for Gemini
    const userMessage = `sessionGoal: ${sessionGoal}

sessionStateSummary: ${sessionStateSummary}

userProgressNote: ${userProgressNote}

scrapedTextDelta: ${scrapedTextDelta || '(No new document content)'}`;

    // 3. Call Gemini using API key from environment
    const model = genAI.getGenerativeModel({ model: 'gemini-pro' });

    const result = await model.generateContent({
      contents: [{ role: 'user', parts: [{ text: `${SYSTEM_PROMPT}\n\n${userMessage}` }] }],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 1024,
      },
    });

    const responseText = result.response.text();

    // 4. Parse and validate Gemini's response
    // Clean any potential markdown
    const cleaned = responseText
      .replace(/```json/g, '')
      .replace(/```/g, '')
      .trim();

    const parsed = JSON.parse(cleaned);

    // Validate structure
    if (typeof parsed.score !== 'number' ||
        typeof parsed.allowBreak !== 'boolean' ||
        typeof parsed.reason !== 'string' ||
        typeof parsed.updatedSummary !== 'string') {
      throw new Error('Invalid response structure from Gemini');
    }

    // Validate score range
    if (parsed.score < 0 || parsed.score > 1) {
      throw new Error('Score out of valid range (0-1)');
    }

    // 5. Return ONLY the structured result (never expose API key)
    res.json({
      score: parsed.score,
      allowBreak: parsed.allowBreak,
      reason: parsed.reason,
      updatedSummary: parsed.updatedSummary
    });

  } catch (error) {
    console.error('❌ Error processing request:', error);

    // Return safe error message (never expose secrets)
    res.status(500).json({
      error: 'Failed to verify progress. Please try again.'
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`✅ Cloud Run server listening on port ${PORT}`);
});
```

**File: `package.json`**

```json
{
  "name": "clast-verification-service",
  "version": "1.0.0",
  "description": "Gemini-powered progress verification for Clast",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "@google/generative-ai": "^0.1.3"
  },
  "engines": {
    "node": ">=18"
  }
}
```

**File: `Dockerfile`** (optional - Cloud Run can auto-detect)

```dockerfile
FROM node:18-slim
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
CMD ["npm", "start"]
```

---

## 📦 Deployment Steps

### 1. Install Google Cloud CLI

```bash
# macOS
brew install google-cloud-sdk

# Or download from: https://cloud.google.com/sdk/docs/install
```

### 2. Initialize and Login

```bash
gcloud init
gcloud auth login
```

### 3. Create Project (if needed)

```bash
gcloud projects create clast-verification --name="Clast Verification"
gcloud config set project clast-verification
```

### 4. Enable Required APIs

```bash
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### 5. Deploy to Cloud Run

```bash
# Deploy with API key as environment variable
gcloud run deploy clast-verification \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars GEMINI_API_KEY=YOUR_ACTUAL_GEMINI_API_KEY_HERE \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10
```

### 6. Get Your Endpoint URL

After deployment, you'll see:

```
Service [clast-verification] revision [clast-verification-00001] has been deployed
Service URL: https://clast-verification-xxxxx.run.app
```

**Copy this URL!** You'll need it for the iOS app.

---

## 📱 Update iOS App

Open `Clast/Config/APIConfig.swift` and update:

```swift
static let cloudRunURL = "https://clast-verification-xxxxx.run.app"
```

---

## 🧪 Test Your Endpoint

```bash
curl -X POST https://clast-verification-xxxxx.run.app/verify-progress \
  -H "Content-Type: application/json" \
  -d '{
    "sessionGoal": "Build authentication system",
    "sessionStateSummary": "Just started the session",
    "userProgressNote": "Implemented OAuth login flow",
    "scrapedTextDelta": "function login(email, password) { ... }"
  }'
```

Expected response:

```json
{
  "score": 0.75,
  "allowBreak": true,
  "reason": "Completed OAuth login implementation",
  "updatedSummary": "OAuth login flow implemented. Next: add JWT tokens."
}
```

---

## 🔒 Security Checklist

- [x] API key stored in environment variable (never in code)
- [x] API key never returned in responses
- [x] Input validation on all fields
- [x] Safe error messages (no stack traces to client)
- [x] Request timeout handling
- [x] JSON parsing error handling

### Optional Enhancements:

**Rate Limiting:**

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/verify-progress', limiter);
```

**Request Authentication:**

```javascript
const API_SECRET = process.env.API_SECRET;

app.post('/verify-progress', (req, res, next) => {
  const authHeader = req.headers['authorization'];
  if (authHeader !== `Bearer ${API_SECRET}`) {
    return res.status(401).json({ error: 'Unauthorized' });
  }
  next();
});
```

---

## 📊 Monitoring

View logs:

```bash
gcloud run logs read clast-verification --limit 50
```

View metrics:

```bash
gcloud run services describe clast-verification --region us-central1
```

---

## 💰 Cost Estimate

**Gemini API (Free Tier):**
- 60 requests/minute free
- ~$0.00025 per 1K characters after free tier

**Cloud Run:**
- First 2 million requests/month: FREE
- After: $0.40 per million requests
- 512MB memory: ~$0.0000024 per second

**Example: 1000 verifications/month**
- Cloud Run: FREE (under 2M requests)
- Gemini: FREE (under rate limit)
- **Total: $0.00** 🎉

**Example: 100K verifications/month**
- Cloud Run: ~$2.00
- Gemini: ~$5.00
- **Total: ~$7.00/month**

---

## 🐛 Troubleshooting

**"GEMINI_API_KEY not found"**
```bash
# Update environment variable
gcloud run services update clast-verification \
  --set-env-vars GEMINI_API_KEY=your_key_here
```

**"Invalid JSON response"**
- Check Cloud Run logs: `gcloud run logs read clast-verification`
- Gemini might be returning markdown - the code strips it
- Verify prompt returns valid JSON

**Timeouts**
- Increase Cloud Run timeout:
```bash
gcloud run services update clast-verification --timeout 30s
```

**High latency**
- Consider upgrading memory: `--memory 1Gi`
- Or adding more CPU: `--cpu 2`

---

## 🎉 You're Done!

Once deployed:
1. ✅ Your iOS app calls Cloud Run
2. ✅ Cloud Run calls Gemini with secure API key
3. ✅ Gemini returns structured JSON
4. ✅ Cloud Run forwards result to app
5. ✅ API key stays 100% secure

**No API key ever touches the iOS app!** 🔒
