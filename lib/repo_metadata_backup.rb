class RepoMetadataBackup
  attr_reader :repo, :config

  delegate :github_client, :s3_client, :s3_bucket_name, to: :config
  delegate :name, :full_name, :updated_at, to: :repo, prefix: true

  def initialize(repo, config)
    @repo = repo
    @config = config
  end

  def save
    ["issues", "pull_requests", "issues_comments", "pull_requests_comments"].each do |type|
      save_backup_if_not_exists(type)
    end
  end

  private

  def save_backup_if_not_exists(type)
    if skip_backup?(type_key(type))
      puts "Skipping #{type} for #{repo_full_name} because last version already exists in S3"
    else
      save_backup(type, send("fetch_#{type}"))
    end
  end

  def fetch_issues
    puts "Fetching issues for #{repo_full_name}"
    github_client.issues(repo_full_name, state: "all").map(&:to_h)
  end

  def fetch_pull_requests
    puts "Fetching pull requests for #{repo_full_name}"
    github_client.pull_requests(repo_full_name, state: "all").map(&:to_h)
  end

  def fetch_issues_comments
    puts "Fetching issues comments for #{repo_full_name}"
    github_client.issues_comments(repo_full_name).map(&:to_h)
  end

  def fetch_pull_requests_comments
    puts "Fetching pull requests comments for #{repo_full_name}"
    github_client.pull_requests_comments(repo_full_name).map(&:to_h)
  end

  def save_backup(type, data)
    json = JSON.pretty_generate(data)

    puts "Pushing #{type} of #{repo_full_name} to S3..."
    s3_client.put_object(
      bucket: s3_bucket_name,
      key: type_key(type),
      body: json
    )
    puts "Pushed #{type} of #{repo_full_name} to S3! ✅"
  end

  def type_key(type)
    "#{repo_name}/#{type}.json"
  end

  def skip_backup?(key)
    s3_object = config.s3_object(key)
    s3_object.exists? &&
      (s3_object.last_modified > 12.hours.ago || s3_object.last_modified > repo_updated_at)
  end
end
