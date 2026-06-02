import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    if (!RESEND_API_KEY) {
      throw new Error('RESEND_API_KEY environment variable is not set')
    }

    const { invitation_ids } = await req.json()
    
    if (!invitation_ids || !Array.isArray(invitation_ids)) {
      return new Response(JSON.stringify({ error: 'Missing or invalid invitation_ids' }), { 
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Fetch the invitations with client and event details
    const { data: invitations, error } = await supabase
      .from('event_invitations')
      .select(`
        id,
        client_profiles (
          id,
          full_name,
          email
        ),
        client_events (
          id,
          title
        )
      `)
      .in('id', invitation_ids)

    if (error) {
      throw new Error(`Database Error: ${error.message}`)
    }
    if (!invitations || invitations.length === 0) {
      throw new Error('Database Error: No valid invitations found for the provided IDs.')
    }

    let sentCount = 0
    let errorCount = 0
    let lastError = ''

    // Send an email for each invitation via Resend
    for (const inv of invitations) {
      const client = inv.client_profiles
      const event = inv.client_events
      
      if (!client?.email) {
        throw new Error(`Client profile for invitation ${inv.id} has no email address.`)
      }

      const acceptURL = `${supabaseUrl}/functions/v1/rsvp?id=${inv.id}&status=confirmed`
      const declineURL = `${supabaseUrl}/functions/v1/rsvp?id=${inv.id}&status=declined`

      const html = `
        <div style="font-family: sans-serif; max-width: 500px; margin: 0 auto; padding: 20px; text-align: center;">
          <h2 style="color: #4A1525;">You are Invited!</h2>
          <p>Dear ${client.full_name},</p>
          <p>You are cordially invited to our upcoming event: <strong>${event.title}</strong>.</p>
          <p>Please let us know if you can make it by clicking one of the options below:</p>
          <br/>
          <a href="${acceptURL}" style="display: inline-block; padding: 12px 24px; background-color: #2D7A5D; color: white; text-decoration: none; border-radius: 8px; font-weight: bold; margin-right: 10px;">✅ Accept</a>
          <a href="${declineURL}" style="display: inline-block; padding: 12px 24px; background-color: #f2f2f2; color: #333; text-decoration: none; border-radius: 8px; font-weight: bold;">❌ Decline</a>
          <br/><br/>
          <p style="color: #666; font-size: 14px;">We hope to see you there!</p>
        </div>
      `

      const res = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${RESEND_API_KEY}`
        },
        body: JSON.stringify({
          from: 'RSMS Events <onboarding@resend.dev>', // Resend testing domain
          to: ['premkur5555@gmail.com'], // Hardcoded for testing since Resend free tier only allows sending to your own email
          subject: `Invitation: ${event.title}`,
          html: html
        })
      })

      if (res.ok) {
        sentCount++
      } else {
        const errText = await res.text()
        lastError = errText
        errorCount++
      }
    }

    if (errorCount > 0) {
      throw new Error(`Resend API Error: ${lastError}`)
    }

    return new Response(JSON.stringify({ 
      success: true, 
      sent: sentCount 
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    })
    
  } catch (err) {
    console.error(err)
    return new Response(JSON.stringify({ error: String(err) }), { 
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
    })
  }
})
