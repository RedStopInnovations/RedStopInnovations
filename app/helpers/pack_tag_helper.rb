# PackTagHelper - Custom Webpacker replacement for static asset management
#
# This helper module replaces Webpacker/Shakapacker functionality after converting
# frontend assets to static files. It provides the same API as webpacker helpers
# but reads from a static manifest.json file instead of dynamic compilation.
#
# Purpose:
# - Maintains compatibility with existing template code using pack tag helpers
# - Reads asset paths from public/packs/manifest.json
# - Handles entrypoint assets (multiple JS/CSS files per pack)
# - Provides fingerprinted asset URLs for cache busting
# - Enables gradual migration from Webpacker to Vite for dashboard assets
#
# Usage:
#   <%= javascript_pack_tag 'frontend' %>  # Loads multiple JS files from entrypoint
#   <%= stylesheet_pack_tag 'frontend' %>  # Loads CSS files from entrypoint
#   <%= asset_pack_path 'static/images/logo.png' %>  # Gets fingerprinted asset path
#
module PackTagHelper
  def javascript_pack_tag(name, **options)
    manifest = load_pack_manifest

    # Get entrypoint assets
    entrypoint = manifest.dig('entrypoints', name)
    if entrypoint && entrypoint['assets'] && entrypoint['assets']['js']
      # Use entrypoint for multiple files (runtime, chunks, main)
      js_files = entrypoint['assets']['js']
    else
      # Fallback to direct manifest lookup
      js_files = [manifest["#{name}.js"]].compact
    end

    if js_files.empty?
      Rails.logger.warn("No JavaScript files found for pack '#{name}' in manifest")
      return ''.html_safe
    end

    js_files.map do |js_file|
      javascript_include_tag(js_file, **options)
    end.join("\n").html_safe
  end

  def stylesheet_pack_tag(name, **options)
    manifest = load_pack_manifest

    # Get entrypoint assets
    entrypoint = manifest.dig('entrypoints', name)
    if entrypoint && entrypoint['assets'] && entrypoint['assets']['css']
      # Use entrypoint for CSS files
      css_files = entrypoint['assets']['css']
    else
      # Fallback to direct manifest lookup
      css_files = [manifest["#{name}.css"]].compact
    end

    if css_files.empty?
      Rails.logger.warn("No CSS files found for pack '#{name}' in manifest")
      return ''.html_safe
    end

    css_files.map do |css_file|
      stylesheet_link_tag(css_file, **options)
    end.join("\n").html_safe
  end

  def asset_pack_path(name)
    manifest = load_pack_manifest

    # Look for the asset in the manifest
    asset_path = manifest[name]

    if asset_path.nil?
      Rails.logger.warn("Asset '#{name}' not found in pack manifest")
      return nil
    end

    asset_path
  end

  private

  def load_pack_manifest
    @pack_manifest ||= begin
      manifest_path = Rails.root.join('public', 'packs', 'manifest.json')
      if File.exist?(manifest_path)
        JSON.parse(File.read(manifest_path))
      else
        Rails.logger.error("Pack manifest not found at #{manifest_path}")
        {}
      end
    end
  end
end
