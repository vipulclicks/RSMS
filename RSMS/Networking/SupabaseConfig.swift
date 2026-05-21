//
//  SupabaseConfig.swift
//  RSMS
//
//  Configuration for Supabase connection.
//  Replace the placeholder values with your actual Supabase project URL and anon key.
//

import Foundation

/// Connection parameters for the Supabase backend.
///
/// Usage:
///   1. Go to your Supabase dashboard → Settings → API
///   2. Copy the "Project URL" and "anon public" key
///   3. Paste them below
///
enum SupabaseConfig {
    /// Your Supabase project URL (e.g., "https://abcdefghijklm.supabase.co")
    static let projectURL = "https://lidoouszbcutddwrxbgy.supabase.co"

    /// Your Supabase anon (public) API key
    static let anonKey = "sb_publishable_X11_v94UKdMch6EBFq1eyA_9jGIJuD8"

    /// Base REST endpoint
    static var restURL: String { "\(projectURL)/rest/v1" }
}
