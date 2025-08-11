class Config
  attr_reader :github_org, :s3_bucket_name

  def initialize(
    github_org:,
    github_token:,
    s3_access_key:,
    s3_secret_key:,
    s3_region:,
    s3_endpoint:,
    s3_bucket_name:
  )
    @github_org = github_org
    @github_token = github_token
    @s3_access_key = s3_access_key
    @s3_secret_key = s3_secret_key
    @s3_region = s3_region
    @s3_endpoint = s3_endpoint
    @s3_bucket_name = s3_bucket_name
  end

  def github_client
    @github_client ||= Octokit::Client.new(access_token: @github_token, auto_paginate: true)
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(
      access_key_id: @s3_access_key,
      secret_access_key: @s3_secret_key,
      region: @s3_region,
      endpoint: @s3_endpoint,
      force_path_style: true,
      ssl_verify_peer: false
    )
  end

  def s3_object(key)
    Aws::S3::Object.new(bucket_name: @s3_bucket_name, key: key, client: s3_client)
  end
end