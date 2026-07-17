import Stripe from 'https://esm.sh/stripe@14.21.0';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2024-04-10',
});

Deno.serve(async (req) => {
  try {
    const { payment_method_id } = await req.json();

    const authHeader = req.headers.get('Authorization')!;
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data: { user } } = await supabase.auth.getUser(
      authHeader.replace('Bearer ', '')
    );
    if (!user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });

    const { data: userData } = await supabase
      .from('users')
      .select('stripe_customer_id, email')
      .eq('id', user.id)
      .single();

    let customerId = userData?.stripe_customer_id;
    if (!customerId) {
      const customer = await stripe.customers.create({
        email: userData?.email ?? user.email,
        metadata: { supabase_uid: user.id },
      });
      customerId = customer.id;
      await supabase.from('users').update({ stripe_customer_id: customerId }).eq('id', user.id);
    }

    await stripe.paymentMethods.attach(payment_method_id, { customer: customerId });

    const pm = await stripe.paymentMethods.retrieve(payment_method_id);
    const card = pm.card!;

    const { data: existing } = await supabase
      .from('user_cards')
      .select('id')
      .eq('user_id', user.id)
      .eq('stripe_pm_id', payment_method_id)
      .maybeSingle();

    if (!existing) {
      await supabase.from('user_cards').insert({
        user_id: user.id,
        stripe_pm_id: payment_method_id,
        holder_name: pm.billing_details.name ?? 'Card Holder',
        last4: card.last4,
        expiry: `${String(card.exp_month).padStart(2, '0')}/${String(card.exp_year).slice(-2)}`,
        card_network: card.brand.charAt(0).toUpperCase() + card.brand.slice(1),
        is_default: false,
      });
    }

    return new Response(JSON.stringify({ success: true, pmId: payment_method_id }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), { status: 500 });
  }
});