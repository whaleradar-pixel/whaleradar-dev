async function notifyOwner(payload) {
  const resendKey = process.env.RESEND_API_KEY;
  if (!resendKey) return false;
  const to = process.env.ADMIN_NOTIFY_EMAIL || process.env.ADMIN_RECOVERY_EMAIL || 'whaleradar@whaleradar.dev';
  const from = process.env.NOTIFY_FROM_EMAIL || 'Whale Radar <onboarding@resend.dev>';
  const plan = String(payload.requested_plan || 'basic').toUpperCase();
  const text = [
    'בקשת הצטרפות חדשה ל-Whale Radar',
    '',
    `שם: ${payload.full_name || '-'}`,
    `טלפון: ${payload.phone || '-'}`,
    `מייל: ${payload.email || '-'}`,
    `ת.ז: ${payload.national_id || '-'}`,
    `מסלול מבוקש: ${plan}`,
    `מקור: ${payload.source || 'website'}`,
    `זמן: ${payload.created_at || new Date().toISOString()}`
  ].join('\n');
  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        authorization: `Bearer ${resendKey}`,
        'content-type': 'application/json'
      },
      body: JSON.stringify({
        from,
        to,
        subject: `בקשת הצטרפות חדשה - ${payload.full_name || 'לקוח'}`,
        text
      })
    });
    return response.ok;
  } catch {
    return false;
  }
}

exports.handler = async (event) => {
  const headers = {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': 'https://whaleradar.dev',
    'access-control-allow-methods': 'POST, OPTIONS',
    'access-control-allow-headers': 'content-type'
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 204, headers, body: '' };
  }

  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, headers, body: JSON.stringify({ error: 'Method not allowed' }) };
  }

  let lead;
  try {
    lead = JSON.parse(event.body || '{}');
  } catch {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Invalid JSON' }) };
  }

  const clean = (value) => String(value || '').replace(/[<>]/g, '').trim();
  const payload = {
    full_name: clean(lead.name),
    phone: clean(lead.phone),
    national_id: clean(lead.id),
    email: clean(lead.email),
    requested_plan: clean(lead.plan || 'basic').toLowerCase(),
    source: 'whaleradar.dev',
    status: 'new',
    created_at: new Date().toISOString()
  };

  if (!payload.full_name || !payload.phone || !['basic', 'pro', 'vip'].includes(payload.requested_plan)) {
    return { statusCode: 400, headers, body: JSON.stringify({ error: 'Missing required fields' }) };
  }

  const notified = await notifyOwner(payload);

  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !serviceKey) {
    return { statusCode: 202, headers, body: JSON.stringify({ ok: true, stored: false, notified }) };
  }

  const response = await fetch(`${supabaseUrl.replace(/\/$/, '')}/rest/v1/leads`, {
    method: 'POST',
    headers: {
      apikey: serviceKey,
      'content-type': 'application/json',
      prefer: 'return=minimal',
      ...(!serviceKey.startsWith('sb_secret_') ? { authorization: `Bearer ${serviceKey}` } : {})
    },
    body: JSON.stringify(payload)
  });

  if (!response.ok) {
    const errorText = await response.text().catch(() => '');
    return { statusCode: 502, headers, body: JSON.stringify({ error: errorText || 'Supabase insert failed' }) };
  }

  return { statusCode: 200, headers, body: JSON.stringify({ ok: true, stored: true, notified }) };
};
