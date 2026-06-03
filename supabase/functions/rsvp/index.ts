import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Content-Type': 'text/html; charset=utf-8'
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const url = new URL(req.url)
    const id = url.searchParams.get('id')
    const status = url.searchParams.get('status')

    if (!id || !status) {
      return new Response("Missing 'id' or 'status' query parameters.", { status: 400 })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { error } = await supabase
      .from('event_invitations')
      .update({ 
        status: status, 
        responded_at: new Date().toISOString() 
      })
      .eq('id', id)

    if (error) {
      return new Response(`Error updating RSVP: ${error.message}`, { status: 500 })
    }

    const isConfirmed = status === 'confirmed'
    const title = isConfirmed ? "✅ RSVP Confirmed!" : "❌ RSVP Declined"
    const message = isConfirmed 
      ? "Thank you! We have recorded your response and look forward to seeing you."
      : "We're sorry you can't make it. We have recorded your response."

    const plainTextResponse = `${title}\n\n${message}`

    return new Response(plainTextResponse, {
      status: 200,
      headers: corsHeaders
    })
  } catch (err) {
    return new Response(String(err), { status: 500, headers: corsHeaders })
  }
})
