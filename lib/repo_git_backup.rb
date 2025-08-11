class RepoGitBackup
  attr_reader :repo, :config

  delegate :github_org, :s3_bucket_name, :s3_client, to: :config
  delegate :name, :full_name, :updated_at, to: :repo, prefix: true

  def initialize(repo, config)
    @repo = repo
    @config = config
  end

  def save
    if repo.private? && running_in_ci?
      puts "⚠️ Skipping #{repo_name} git backup: Private repo backup is not supported in CI"
      return
    end

    if skip_backup?(key)
      puts "Skipping #{repo_name} git backup because last version already exists in S3"
      return
    end

    system("git clone --mirror https://github.com/#{github_org}/#{repo_name}.git #{git_repo_path}")
    system("tar -czf #{archive_path} -C /tmp #{repo_name}.git")

    puts "Pushing #{repo_name} git archive..."
    s3_client.put_object(
      bucket: s3_bucket_name,
      key: key,
      body: File.open(archive_path)
    )
    puts "Pushed #{repo_name} git archive to S3! ✅"
  ensure
    FileUtils.rm_rf(git_repo_path)
    FileUtils.rm_rf(archive_path)
  end

  private

  def key
    "#{repo_name}/repo.tar.gz"
  end

  def git_repo_path
    "/tmp/#{repo_name}.git"
  end

  def archive_path
    "/tmp/#{repo_name}.tar.gz"
  end

  def skip_backup?(key)
    s3_object = config.s3_object(key)
    s3_object.exists? &&
      (s3_object.last_modified > 12.hours.ago || s3_object.last_modified > repo_updated_at)
  end

  def running_in_ci?
    ENV["CI"] == "true"
  end
end
