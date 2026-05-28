import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import Stripe from "npm:stripe@14";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

const PRICE_MAP: Record<string, number> = {
  basic: 4900,
  pro: 9900,
  vip: 19900,
};

const PLAN_NAMES: Record<string, string> = {
  basic: "Basic",
  pro: "Pro",
  vip: "VIP",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!stripeSecretKey || !supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Missing required environment variables");
    }

    const stripe = new Stripe(stripeSecretKey, {
      apiVersion: "2024-04-10",
    });

    const _supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    if (req.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Method not allowed" }),
        { status: 405, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const body = await req.json();
    const {
      planId,
      billingCycle,
      userId,
      userEmail,
      success_url,
      cancel_url,
    } = body as {
      planId: string;
      billingCycle: "monthly" | "yearly";
      userId: string;
      userEmail: string;
      success_url?: string;
      cancel_url?: string;
    };

    // Validate required fields
    if (!planId || !billingCycle || !userId || !userEmail) {
      return new Response(
        JSON.stringify({ error: "Missing required fields: planId, billingCycle, userId, userEmail" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!["basic", "pro", "vip"].includes(planId)) {
      return new Response(
        JSON.stringify({ error: "Invalid planId. Must be one of: basic, pro, vip" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    if (!["monthly", "yearly"].includes(billingCycle)) {
      return new Response(
        JSON.stringify({ error: "Invalid billingCycle. Must be 'monthly' or 'yearly'" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Calculate price
    const monthlyPrice = PRICE_MAP[planId];
    const unitAmount = billingCycle === "yearly"
      ? monthlyPrice * 10 // 2 months free
      : monthlyPrice;

    const defaultBaseUrl = "https://app.whaleradar.dev";
    const successUrl = success_url || `${defaultBaseUrl}?checkout=success&plan=${planId}`;
    const cancelUrl = cancel_url || `${defaultBaseUrl}?checkout=cancelled`;

    const billingLabel = billingCycle === "yearly" ? "שנתי (2 חודשים חינם)" : "חודשי";
    const planLabel = `${PLAN_NAMES[planId]} - ${billingLabel}`;

    const session = await stripe.checkout.sessions.create({
      mode: "payment",
      customer_email: userEmail,
      line_items: [
        {
          price_data: {
            currency: "ils",
            unit_amount: unitAmount,
            product_data: {
              name: `Whale Radar - תוכנית ${planLabel}`,
              description: `גישה לתוכנית ${PLAN_NAMES[planId]} ב-Whale Radar`,
              images: ["https://app.whaleradar.dev/logo.png"],
            },
          },
          quantity: 1,
        },
      ],
      metadata: {
        userId,
        planId,
        billingCycle,
      },
      success_url: successUrl,
      cancel_url: cancelUrl,
      locale: "he",
      payment_intent_data: {
        metadata: {
          userId,
          planId,
          billingCycle,
        },
      },
    });

    return new Response(
      JSON.stringify({ url: session.url }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal server error";
    console.error("[stripe-checkout] Error:", message);

    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
