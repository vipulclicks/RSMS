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

    const isConfirmed = status === 'confirmed'

    // If it's a GET request (like from an email click or scanner), 
    // show a confirmation page to prevent accidental pre-fetching by email clients.
    if (req.method === 'GET') {
      const actionText = isConfirmed ? 'Accept' : 'Decline'
      const buttonColor = isConfirmed ? '#2D7A5D' : '#f2f2f2'
      const textColor = isConfirmed ? 'white' : '#333'
      
      const html = `
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>RSVP Confirmation</title>
          </head>
          <body style="font-family: sans-serif; text-align: center; padding: 40px 20px; background-color: #FAF8F5;">
            <div style="max-width: 400px; margin: 0 auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
              <h2 style="color: #4A1525; margin-bottom: 20px;">Confirm RSVP</h2>
              <p style="color: #666; margin-bottom: 30px;">Are you sure you want to <strong>${actionText}</strong> this invitation?</p>
              <form method="POST" action="${req.url}">
                <button type="submit" style="display: inline-block; padding: 14px 28px; background-color: ${buttonColor}; color: ${textColor}; text-decoration: none; border-radius: 8px; font-weight: bold; border: none; cursor: pointer; font-size: 16px; width: 100%;">
                  Yes, ${actionText}
                </button>
              </form>
            </div>
          </body>
        </html>
      `
      return new Response(html, { headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' } })
    }

    // Only process the actual database update on POST

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

    const isConfirmedText = isConfirmed
    const title = isConfirmedText ? "✅ RSVP Confirmed!" : "❌ RSVP Declined"
    const message = isConfirmedText 
      ? "Thank you! We have recorded your response and look forward to seeing you."
      : "We're sorry you can't make it. We have recorded your response."

    const successHtml = `
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>RSVP Success</title>
        </head>
        <body style="font-family: sans-serif; text-align: center; padding: 40px 20px; background-color: #FAF8F5;">
          <div style="max-width: 400px; margin: 0 auto; background: white; padding: 30px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.1);">
            <h2 style="color: #4A1525; margin-bottom: 15px;">${title}</h2>
            <p style="color: #666; line-height: 1.5;">${message}</p>
          </div>
        </body>
      </html>
    `

    return new Response(successHtml, {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' }
    })
  } catch (err) {
    return new Response(String(err), { status: 500, headers: corsHeaders })
  }
})
