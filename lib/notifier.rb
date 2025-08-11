class Notifier
  def self.notify(message)
    url = ENV["NOTIFICATION_WEBHOOK_URL"]
    return if url.blank?

    payload = { text: message }
    Faraday.post(url) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.dump(payload)
    end
  end
end
