require 'net/http'
require 'uri'
require 'fileutils'
require 'cgi'
require 'set'

module Jekyll
  module Badges
    class Generator < Jekyll::Generator
      safe true
      priority :lowest

      def generate(site)
        # Store the site object for later use
        site.config['badges_site'] = site
      end
    end

    Jekyll::Hooks.register :site, :post_write do |site|
      badges_dir = File.join(site.dest, 'assets', 'img', 'badges')
      FileUtils.mkdir_p(badges_dir)
      
      Jekyll.logger.info "Badges:", "Post-write hook triggered"
      Jekyll.logger.info "Badges:", "Site destination: #{site.dest}"
      Jekyll.logger.info "Badges:", "Creating badges directory: #{badges_dir}"
      
      # Download Google Scholar citation badges
      download_scholar_badges(site, badges_dir)
      
      Jekyll.logger.info "Badges:", "All badges download complete!"
    end

    def self.download_scholar_badges(site, badges_dir)
      citations = site.data['citations']['papers'] rescue nil
      
      unless citations && !citations.empty?
        Jekyll.logger.warn "Scholar Badges:", "No citations found in data"
        return
      end

      # Collect unique citation counts
      citation_counts = Set.new
      citations.each do |paper_key, paper_data|
        citation_count = paper_data['citations'] || 0
        citation_counts.add(citation_count)
      end

      Jekyll.logger.info "Scholar Badges:", "Downloading badges for #{citation_counts.length} unique citation counts..."
      
      count = 0
      citation_counts.each do |citation_count|
        if download_scholar_badge(citation_count, badges_dir)
          count += 1
        end
      end

      Jekyll.logger.info "Scholar Badges:", "#{count} scholar badges saved to: #{badges_dir}"
    end


    def self.download_scholar_badge(citation_count, output_dir)
      # Create the shields.io URL for scholar badge
      encoded_count = CGI.escape(citation_count.to_s)
      badge_url = "https://img.shields.io/badge/scholar-#{encoded_count}-4285F4?logo=googlescholar&labelColor=beige"
      
      # Create safe filename using citation count
      filename = "scholar-#{citation_count}.svg"
      output_path = File.join(output_dir, filename)

      download_file(badge_url, output_path, "Scholar: #{citation_count} citations")
    end

    def self.download_file(url, output_path, description)
      # Skip if already exists
      if File.exist?(output_path)
        Jekyll.logger.debug "Badges:", "Skipping #{description} (already exists)"
        return false
      end

      begin
        uri = URI.parse(url)
        response = Net::HTTP.get_response(uri)

        if response.is_a?(Net::HTTPSuccess)
          File.write(output_path, response.body)
          Jekyll.logger.info "Badges:", "✓ Downloaded #{description}"
          return true
        else
          Jekyll.logger.warn "Badges:", "Failed to download #{description}: HTTP #{response.code}"
          return false
        end
      rescue => e
        Jekyll.logger.error "Badges:", "Error downloading #{description}: #{e.message}"
        return false
      end
    end

    def self.sanitize_filename(str)
      str.gsub(/[\/\.\:]/, '_')
    end
  end
end
