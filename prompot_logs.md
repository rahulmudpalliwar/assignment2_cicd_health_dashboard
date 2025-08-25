# Prompt Logs

This file contains example prompts used with AI tools (Cursor/Copilot/ChatGPT) during development.

Examples:

1. Prompt: “How can I safely test email alerts for CI/CD pipeline failures without triggering real builds?”

Response: “Insert a failing build record into the DB (conclusion='failure'), or post a webhook payload with failure status to /api/webhook/github or /api/webhook/jenkins. Ensure SMTP_* and ALERT_TO are set. The backend dedupes by build external_id; use a fresh id for each test. Verify an entry is created in alerts table and email is delivered.”

2. Prompt: “What’s the simplest way to serve a React (Vite) app and connect it to a Node.js API locally and in Docker?”

Response: “Run React dev server on 5173 and expose VITE_API_BASE_URL=http://localhost:3000 for API calls. In Docker, run frontend and backend as separate services; map 5173 and 3000. Use CORS on the API. For production, build the React app and serve via a static server or reverse proxy, or keep dev server for simplicity.”

3. Prompt: "how can I test email alert?"
Response: 
"a) Use a Mock Failure Trigger:
Create a dummy GitHub Actions or Jenkins job that intentionally fails (e.g., run exit 1).
Ensure it's picked up by your polling logic or webhook handler.

b) Configure a Test Email Recipient
Use a test email address (like your own or a disposable inbox) in your alerting config.
Make sure SMTP credentials and sender details are valid.

c) Trigger the Alert Manually
Call your alert function directly from a test route in your Node.js backend:"

4. Prompt: "Create an architecture diagram"
Response: "Provided a textual architecture summary, including components like Jenkins, python and React.js."
