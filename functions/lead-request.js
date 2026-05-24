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

  const supabaseUrl = process.env.SUPABASE_URL;
  const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!supabaseUrl || !serviceKey) {
    return { statusCode: 202, headers, body: JSON.stringify({ ok: true, stored: false }) };
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

  return { statusCode: 200, headers, body: JSON.stringify({ ok: true, stored: true }) };
};
