import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { Resend } from "npm:resend@3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

// ---------------------------------------------------------------------------
// HTML email layout wrapper
// ---------------------------------------------------------------------------
function layout(bodyContent: string, subject: string): string {
  return `<!DOCTYPE html>
<html lang="he" dir="rtl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>${subject}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background-color: #0b0f1a;
      color: #e2e8f0;
      font-family: 'Segoe UI', Tahoma, Arial, sans-serif;
      direction: rtl;
      text-align: right;
    }
    .wrapper {
      max-width: 600px;
      margin: 0 auto;
      padding: 40px 20px;
    }
    .header {
      text-align: center;
      padding-bottom: 32px;
      border-bottom: 1px solid #1e293b;
      margin-bottom: 32px;
    }
    .logo-text {
      font-size: 28px;
      font-weight: 800;
      color: #06b6d4;
      letter-spacing: 1px;
    }
    .logo-sub {
      font-size: 13px;
      color: #64748b;
      margin-top: 4px;
    }
    .card {
      background-color: #111827;
      border: 1px solid #1e293b;
      border-radius: 12px;
      padding: 32px;
      margin-bottom: 24px;
    }
    .card h1 {
      font-size: 22px;
      font-weight: 700;
      color: #f1f5f9;
      margin-bottom: 16px;
      line-height: 1.4;
    }
    .card p {
      font-size: 15px;
      color: #94a3b8;
      line-height: 1.7;
      margin-bottom: 12px;
    }
    .card p:last-child { margin-bottom: 0; }
    .highlight {
      color: #06b6d4;
      font-weight: 600;
    }
    .badge {
      display: inline-block;
      background: linear-gradient(135deg, #0e7490, #06b6d4);
      color: #fff;
      font-size: 13px;
      font-weight: 700;
      padding: 4px 14px;
      border-radius: 99px;
      margin-bottom: 16px;
      letter-spacing: 0.5px;
    }
    .otp-box {
      background-color: #0b0f1a;
      border: 2px solid #06b6d4;
      border-radius: 10px;
      padding: 20px;
      text-align: center;
      margin: 20px 0;
    }
    .otp-code {
      font-size: 40px;
      font-weight: 800;
      letter-spacing: 12px;
      color: #06b6d4;
      font-family: 'Courier New', monospace;
    }
    .otp-hint {
      font-size: 13px;
      color: #64748b;
      margin-top: 8px;
    }
    .info-row {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding: 10px 0;
      border-bottom: 1px solid #1e293b;
      font-size: 14px;
    }
    .info-row:last-child { border-bottom: none; }
    .info-label { color: #64748b; }
    .info-value { color: #e2e8f0; font-weight: 600; }
    .btn {
      display: inline-block;
      background: linear-gradient(135deg, #0e7490, #06b6d4);
      color: #fff !important;
      text-decoration: none;
      font-size: 15px;
      font-weight: 700;
      padding: 13px 32px;
      border-radius: 8px;
      margin-top: 20px;
    }
    .footer {
      text-align: center;
      padding-top: 24px;
      border-top: 1px solid #1e293b;
    }
    .footer p {
      font-size: 12px;
      color: #475569;
      line-height: 1.6;
      margin-bottom: 6px;
    }
    .footer a {
      color: #06b6d4;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="header">
      <div class="logo-text">🐋 Whale Radar</div>
      <div class="logo-sub">מעקב חכם אחר שוקי ההון</div>
    </div>

    ${bodyContent}

    <div class="footer">
      <p>קיבלת מייל זה מכיוון שאתה רשום ב-Whale Radar.</p>
      <p>
        שאלות? פנה אלינו בכתובת
        <a href="mailto:support@whaleradar.dev">support@whaleradar.dev</a>
      </p>
      <p>
        <a href="https://app.whaleradar.dev">app.whaleradar.dev</a>
        &nbsp;·&nbsp;
        <a href="https://app.whaleradar.dev/unsubscribe">הסר מהרשימה</a>
      </p>
      <p style="margin-top:10px; color:#334155;">
        © ${new Date().getFullYear()} Whale Radar. כל הזכויות שמורות.<br/>
        המידע המוצג אינו מהווה ייעוץ השקעות. השקעה בשוק ההון כרוכה בסיכון.
      </p>
    </div>
  </div>
</body>
</html>`;
}

// ---------------------------------------------------------------------------
// Email templates
// ---------------------------------------------------------------------------

function welcomeTemplate(data: { name?: string }): { subject: string; html: string } {
  const name = data.name || "משתמש יקר";
  const subject = "ברוך הבא ל-Whale Radar! 🐋";
  const body = `
    <div class="card">
      <div class="badge">ברוך הבא</div>
      <h1>שמחים שהצטרפת, ${name}!</h1>
      <p>
        ברוך הבא ל-<span class="highlight">Whale Radar</span> — הפלטפורמה החכמה למעקב אחר
        תנועות כסף גדולות בשוק ההון.
      </p>
      <p>
        עם החשבון החינמי שלך תוכל להתחיל לגלות הזדמנויות בשוק, לעקוב אחר סיגנלים,
        ולקבל התראות בזמן אמת.
      </p>
      <p>
        רוצה גישה מלאה? שדרג לתוכנית <span class="highlight">Basic, Pro או VIP</span>
        ותקבל נתונים מתקדמים, ניתוחים עמוקים ועוד.
      </p>
      <a href="https://app.whaleradar.dev/pricing" class="btn">גלה את התוכניות שלנו</a>
    </div>
  `;
  return { subject, html: layout(body, subject) };
}

function subscriptionConfirmedTemplate(data: {
  planName?: string;
  expiryDate?: string;
  billingCycle?: string;
}): { subject: string; html: string } {
  const planName = data.planName || "Pro";
  const expiryDate = data.expiryDate
    ? new Date(data.expiryDate).toLocaleDateString("he-IL", {
        year: "numeric",
        month: "long",
        day: "numeric",
      })
    : "—";
  const billingLabel = data.billingCycle === "yearly" ? "שנתי" : "חודשי";
  const subject = `המנוי שלך ל-Whale Radar ${planName} אושר ✅`;
  const body = `
    <div class="card">
      <div class="badge">מנוי פעיל</div>
      <h1>המנוי שלך אושר בהצלחה!</h1>
      <p>תודה על רכישתך. הגישה לתוכנית <span class="highlight">${planName}</span> שלך פעילה עכשיו.</p>

      <div style="margin: 20px 0;">
        <div class="info-row">
          <span class="info-label">תוכנית</span>
          <span class="info-value">${planName}</span>
        </div>
        <div class="info-row">
          <span class="info-label">סוג חיוב</span>
          <span class="info-value">${billingLabel}</span>
        </div>
        <div class="info-row">
          <span class="info-label">תוקף עד</span>
          <span class="info-value">${expiryDate}</span>
        </div>
        <div class="info-row">
          <span class="info-label">סטטוס</span>
          <span class="info-value highlight">✓ פעיל</span>
        </div>
      </div>

      <p>כעת יש לך גישה מלאה לכל הפיצ'רים של תוכנית ${planName}. התחל לגלות הזדמנויות עכשיו.</p>
      <a href="https://app.whaleradar.dev/dashboard" class="btn">כניסה לדשבורד</a>
    </div>
  `;
  return { subject, html: layout(body, subject) };
}

function subscriptionExpiringTemplate(data: {
  daysLeft?: number;
  planName?: string;
}): { subject: string; html: string } {
  const daysLeft = data.daysLeft ?? 7;
  const planName = data.planName || "Pro";
  const subject = `המנוי שלך ל-Whale Radar יפוג בעוד ${daysLeft} ימים ⚠️`;
  const urgencyColor = daysLeft <= 3 ? "#f97316" : "#06b6d4";
  const body = `
    <div class="card">
      <div class="badge">תזכורת חשובה</div>
      <h1>המנוי שלך עומד לפוג</h1>
      <p>
        רצינו להזכיר לך שתוכנית <span class="highlight">${planName}</span> שלך תפוג בעוד
        <span style="color:${urgencyColor}; font-weight:800; font-size:18px;"> ${daysLeft} ימים</span>.
      </p>
      <p>
        כדי להמשיך ליהנות מגישה מלאה לכל הסיגנלים, ההתראות והניתוחים — חדש את המנוי שלך עוד היום.
      </p>
      <p>
        אל תפספס אף הזדמנות בשוק — <span class="highlight">חדש עכשיו וחסוך 2 חודשים</span>
        עם תוכנית שנתית.
      </p>
      <a href="https://app.whaleradar.dev/pricing" class="btn">חדש את המנוי עכשיו</a>
    </div>
  `;
  return { subject, html: layout(body, subject) };
}

function otpTemplate(data: { code?: string; purpose?: string }): {
  subject: string;
  html: string;
} {
  const code = data.code || "------";
  const subject = `קוד האימות שלך ל-Whale Radar: ${code}`;
  const body = `
    <div class="card">
      <div class="badge">אימות זהות</div>
      <h1>קוד האימות שלך</h1>
      <p>השתמש בקוד הבא כדי לאמת את ${data.purpose === "login" ? "הכניסה" : "כתובת האימייל"} שלך:</p>

      <div class="otp-box">
        <div class="otp-code">${code}</div>
        <div class="otp-hint">הקוד תקף ל-10 דקות בלבד</div>
      </div>

      <p>אם לא ביקשת קוד זה, אנא התעלם ממייל זה.</p>
      <p style="font-size:13px; color:#475569;">
        לעולם לא נבקש ממך לשתף קוד זה עם אף אחד, כולל צוות התמיכה שלנו.
      </p>
    </div>
  `;
  return { subject, html: layout(body, subject) };
}

function customTemplate(data: {
  title?: string;
  message?: string;
}): { subject: string; html: string } {
  const title = data.title || "הודעה מ-Whale Radar";
  const message = data.message || "";
  const subject = title;
  const body = `
    <div class="card">
      <h1>${title}</h1>
      <p>${message.replace(/\n/g, "<br/>")}</p>
    </div>
  `;
  return { subject, html: layout(body, subject) };
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

type EmailType = "welcome" | "subscription_confirmed" | "subscription_expiring" | "otp" | "custom";

interface EmailRequest {
  to: string;
  subject?: string;
  type: EmailType;
  // deno-lint-ignore no-explicit-any
  data: Record<string, any>;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail = Deno.env.get("FROM_EMAIL") || "whaleradar@whaleradar.dev";

    if (!resendApiKey) {
      throw new Error("Missing required environment variable: RESEND_API_KEY");
    }

    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const body = (await req.json()) as EmailRequest;
    const { to, type, data } = body;

    if (!to || !type) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: to, type" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const validTypes: EmailType[] = [
      "welcome",
      "subscription_confirmed",
      "subscription_expiring",
      "otp",
      "custom",
    ];
    if (!validTypes.includes(type)) {
      return new Response(
        JSON.stringify({ error: `Invalid type. Must be one of: ${validTypes.join(", ")}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Build template
    let subject: string;
    let html: string;

    switch (type) {
      case "welcome": {
        ({ subject, html } = welcomeTemplate(data));
        break;
      }
      case "subscription_confirmed": {
        ({ subject, html } = subscriptionConfirmedTemplate(data));
        break;
      }
      case "subscription_expiring": {
        ({ subject, html } = subscriptionExpiringTemplate(data));
        break;
      }
      case "otp": {
        ({ subject, html } = otpTemplate(data));
        break;
      }
      case "custom": {
        ({ subject, html } = customTemplate(data));
        break;
      }
    }

    // Allow caller to override the generated subject
    const finalSubject = body.subject || subject!;

    const resend = new Resend(resendApiKey);

    const { data: sendData, error: sendError } = await resend.emails.send({
      from: `Whale Radar <${fromEmail}>`,
      to: [to],
      subject: finalSubject,
      html: html!,
    });

    if (sendError) {
      console.error("[send-email] Resend error:", sendError);
      throw new Error(`Failed to send email: ${sendError.message}`);
    }

    console.log(`[send-email] Sent type=${type} to=${to} id=${sendData?.id}`);

    return new Response(
      JSON.stringify({ success: true, id: sendData?.id }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal server error";
    console.error("[send-email] Error:", message);

    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
