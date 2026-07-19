require 'json'
require 'net/http'
require 'uri'

module Jekyll
  # Fetches GitHub API data for repos and users listed in _data/repositories.yml
  # and stores the results in site.data['github_meta'] for use in Liquid templates.
  #
  # Reads the GITHUB_TOKEN environment variable for authenticated requests
  # (higher rate limit: 5000/h vs 60/h unauthenticated).
  class GitHubMetadataGenerator < Jekyll::Generator
    safe true
    priority :high

    API_BASE = 'https://api.github.com'.freeze

    # GraphQL query: this-year commits (public + opted-in private)
    CONTRIBUTIONS_QUERY = <<~GRAPHQL.freeze
      query($login: String!) {
        user(login: $login) {
          contributionsCollection {
            totalCommitContributions
            restrictedContributionsCount
          }
        }
      }
    GRAPHQL

    def generate(site)
      token = ENV['GITHUB_TOKEN']
      repos_config = site.data.dig('repositories', 'github_repos') || []
      users_config = site.data.dig('repositories', 'github_users') || []

      meta = { 'repos' => {}, 'users' => {} }

      repos_config.each do |repo|
        Jekyll.logger.info 'GitHubMeta:', "Fetching repo #{repo}"
        data = fetch_json("#{API_BASE}/repos/#{repo}", token)
        meta['repos'][repo] = data if data
      end

      users_config.each do |user|
        Jekyll.logger.info 'GitHubMeta:', "Fetching user #{user}"
        data = fetch_json("#{API_BASE}/users/#{user}", token)
        next unless data

        # Total stars across all own repos
        all_repos = fetch_json("#{API_BASE}/users/#{user}/repos?per_page=100&sort=stars", token) || []
        data['total_stars'] = all_repos.sum { |r| r['stargazers_count'].to_i }

        # PRs authored (merged + open)
        prs = fetch_json("#{API_BASE}/search/issues?q=type:pr+author:#{user}&per_page=1", token)
        data['total_prs'] = prs ? prs['total_count'].to_i : 0

        # Issues authored
        issues = fetch_json("#{API_BASE}/search/issues?q=type:issue+author:#{user}&per_page=1", token)
        data['total_issues'] = issues ? issues['total_count'].to_i : 0

        # Commits this year via GraphQL (requires token for private contributions)
        gql = fetch_graphql(CONTRIBUTIONS_QUERY, { 'login' => user }, token)
        if gql
          contrib = gql.dig('user', 'contributionsCollection')
          data['total_commits'] = contrib['totalCommitContributions'].to_i +
                                   contrib['restrictedContributionsCount'].to_i
        end

        meta['users'][user] = data
      end

      site.data['github_meta'] = meta
    end

    private

    def fetch_graphql(query, variables, token)
      return nil unless token && !token.empty?

      uri = URI('https://api.github.com/graphql')
      body = JSON.generate({ query: query, variables: variables })

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        req = Net::HTTP::Post.new(uri.request_uri, {
          'Content-Type'        => 'application/json',
          'Authorization'       => "Bearer #{token}",
          'User-Agent'          => 'Jekyll-GitHub-Meta/1.0',
          'X-GitHub-Api-Version' => '2022-11-28'
        })
        req.body = body
        http.request(req)
      end

      unless res.code.to_i == 200
        Jekyll.logger.warn 'GitHubMeta:', "GraphQL HTTP #{res.code}"
        return nil
      end

      JSON.parse(res.body)['data']
    rescue StandardError => e
      Jekyll.logger.warn 'GitHubMeta:', "GraphQL error: #{e.message}"
      nil
    end

    def fetch_json(url, token)
      uri = URI(url)
      headers = {
        'Accept' => 'application/vnd.github+json',
        'User-Agent' => 'Jekyll-GitHub-Meta/1.0',
        'X-GitHub-Api-Version' => '2022-11-28'
      }
      headers['Authorization'] = "Bearer #{token}" if token && !token.empty?

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.get(uri.request_uri, headers)
      end

      unless res.code.to_i == 200
        Jekyll.logger.warn 'GitHubMeta:', "HTTP #{res.code} for #{url}"
        return nil
      end

      JSON.parse(res.body)
    rescue StandardError => e
      Jekyll.logger.warn 'GitHubMeta:', "Error fetching #{url}: #{e.message}"
      nil
    end
  end
end
