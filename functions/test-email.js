exports.handler = async () => {
  const headers = {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': 'https://whaleradar.dev'
  };

  const resendKey = process.env.RESEND_API_KEY;
  const to = process.env.ADMIN_NOTIFY_EMAIL || 'whaleradar@whaleradar.dev';
  const from = process.env.NOTIFY_FROM_EMAIL || 'Whale Radar <onboarding@resend.dev>';

  if (!resendKey) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        ok: false,
        step: 'env',
        error: 'RESEND_API_KEY is missing in Netlify Functions'
      })
    };
  }

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
        subject: 'Whale Radar - בדיקת מייל',
        text: 'בדיקת מייל מ-Netlify Functions. אם קיבלת את ההודעה הזו, Resend מחובר.'
      })
    });

    const text = await response.text().catch(() => '');
    return {
      statusCode: response.ok ? 200 : 502,
      headers,
      body: JSON.stringify({
        ok: response.ok,
        step: 'resend',
        status: response.status,
        to,
        from,
        response: text
      })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({
        ok: false,
        step: 'network',
        error: error.message || 'Resend request failed'
      })
    };
  }
};
