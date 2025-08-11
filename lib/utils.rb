module Utils
  def self.with_retry(label:, times: 3)
    attempts = 0
    begin
      yield
    rescue => e
      attempts += 1
      puts "[RETRY] #{label} failed (#{attempts}/#{times}): #{e.class} - #{e.message}"
      raise e if attempts >= times
      sleep 2**attempts
      retry
    end
  end
end
