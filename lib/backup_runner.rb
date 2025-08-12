class BackupRunner
  def self.run
    new.run
  end

  attr_reader :config

  delegate :github_client, :github_org, to: :config

  def initialize
    @config = Config.new(
      github_org: ENV.fetch("GH_ORG_NAME"),
      github_token: ENV.fetch("GH_TOKEN"),
      s3_access_key: ENV.fetch("S3_ACCESS_KEY"),
      s3_secret_key: ENV.fetch("S3_SECRET_KEY"),
      s3_region: ENV.fetch("S3_REGION"),
      s3_endpoint: ENV.fetch("S3_ENDPOINT"),
      s3_bucket_name: ENV.fetch("S3_BUCKET_NAME")
    )
  end

  def run
    repos.each do |repo|
      save_backup(repo)
    end
  end

  private

  def repos
    @repos ||= github_client.org_repos(github_org).reject do |repo|
      repo.archived? || repo.fork?
    end
  end

  def save_backup(repo)
    puts "== Backing up #{repo.full_name}"

    begin
      Utils.with_retry(label: "#{repo.full_name} Git backup") do
        RepoGitBackup.new(repo, config).save
      end
      Utils.with_retry(label: "#{repo.full_name} metadata backup") do
        RepoMetadataBackup.new(repo, config).save
      end

      Notifier.notify(":white_check_mark: Backup succeeded for *#{repo.full_name}*")
    rescue => e
      puts "[ERROR] Backup failed for #{repo.full_name}: #{e.class} - #{e.message}"
      Notifier.notify(":x: Backup failed for *#{repo.full_name}*: `#{e.message}`")
    end
  end
end
