import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import Stripe from "npm:stripe@14";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, X-Client-Info, Apikey",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  try {
    const stripeSecretKey = Deno.env.get("STRIPE_SECRET_KEY");
    const stripeWebhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET");
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!stripeSecretKey || !stripeWebhookSecret || !supabaseUrl || !supabaseServiceRoleKey) {
      throw new Error("Missing required environment variables");
    }

    const stripe = new Stripe(stripeSecretKey, {
      apiVersion: "2024-04-10",
    });

    const supabase = createClient(supabaseUrl, supabaseServiceRoleKey);

    // Read raw body for signature verification
    const rawBody = await req.text();
    const signature = req.headers.get("stripe-signature");

    if (!signature) {
      return new Response(
        JSON.stringify({ error: "Missing stripe-signature header" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Verify webhook signature
    let event: Stripe.Event;
    try {
      event = await stripe.webhooks.constructEventAsync(rawBody, signature, stripeWebhookSecret);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : "Webhook signature verification failed";
      console.error("[stripe-webhook] Signature verification failed:", message);
      return new Response(
        JSON.stringify({ error: `Webhook signature verification failed: ${message}` }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    console.log("[stripe-webhook] Received event:", event.type, event.id);

    if (event.type === "checkout.session.completed") {
      const session = event.data.object as Stripe.Checkout.Session;

      const { userId, planId, billingCycle } = session.metadata as {
        userId: string;
        planId: string;
        billingCycle: "monthly" | "yearly";
      };

      if (!userId || !planId || !billingCycle) {
        console.error("[stripe-webhook] Missing metadata fields:", session.metadata);
        return new Response(
          JSON.stringify({ error: "Missing required metadata fields" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
        );
      }

      // Calculate expiry date
      const now = new Date();
      const expiresAt = new Date(now);
      if (billingCycle === "yearly") {
        expiresAt.setDate(expiresAt.getDate() + 365);
      } else {
        expiresAt.setDate(expiresAt.getDate() + 30);
      }

      // Update profile in Supabase
      const { error: updateError } = await supabase
        .from("profiles")
        .update({
          subscription_plan: planId,
          subscription_started_at: now.toISOString(),
          subscription_expires_at: expiresAt.toISOString(),
          updated_at: now.toISOString(),
        })
        .eq("id", userId);

      if (updateError) {
        console.error("[stripe-webhook] Failed to update profile:", updateError);
        throw new Error(`Failed to update profile: ${updateError.message}`);
      }

      console.log(
        `[stripe-webhook] Updated subscription for user ${userId}: plan=${planId}, billingCycle=${billingCycle}, expires=${expiresAt.toISOString()}`,
      );
    } else {
      // Log unhandled event types but return 200 so Stripe doesn't retry
      console.log("[stripe-webhook] Unhandled event type:", event.type);
    }

    return new Response(
      JSON.stringify({ received: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : "Internal server error";
    console.error("[stripe-webhook] Error:", message);

    return new Response(
      JSON.stringify({ error: message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
