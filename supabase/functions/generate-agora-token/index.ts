import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { RtcTokenBuilder, RtcRole } from "https://esm.sh/agora-token@2.0.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization")!;
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    // Verify the caller is a logged-in Supabase user — don't hand out
    // tokens to unauthenticated requests.
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser();

    if (userError || !user) {
      console.log("[AGORA-TOKEN] ERROR | no valid user session");
      return new Response(
        JSON.stringify({ error: "Not authenticated" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { channelName } = await req.json();
    if (!channelName || typeof channelName !== "string") {
      console.log("[AGORA-TOKEN] ERROR | missing channelName");
      return new Response(
        JSON.stringify({ error: "channelName is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const appId = Deno.env.get("AGORA_APP_ID")!;
    const appCertificate = Deno.env.get("AGORA_APP_CERTIFICATE")!;

    // Use a numeric uid derived from the user's Supabase id so both
    // sides of the call can identify who's who inside the Agora channel.
    // Agora needs a uint32, so we hash the UUID down to a stable number.
    const uid = Math.abs(
      user.id.split("").reduce((acc, ch) => (acc * 31 + ch.charCodeAt(0)) | 0, 0)
    ) % 1000000000;

    const expirationTimeInSeconds = 3600; // 1 hour — plenty for a single call
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      RtcRole.PUBLISHER,
      privilegeExpiredTs
    );

    console.log(
      `[AGORA-TOKEN] OK | user=${user.id} channel=${channelName} uid=${uid}`
    );

    return new Response(
      JSON.stringify({ token, uid, appId, channelName }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.log(`[AGORA-TOKEN] ERROR | ${e.message}`);
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});