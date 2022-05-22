class Proxy
  attr_accessor :url
  attr_accessor :tid
  attr_accessor :passes
  attr_accessor :failures
  attr_accessor :message

  def initialize(url)
    @url = url
    @passes = Rails.cache.fetch("passes:#{url}") { 0 } || 0
    @failures = Rails.cache.fetch("failures:#{url}") { 0 } || 0
  end

  def cache_write
    Rails.cache.write("passes:#{url}", passes)
    Rails.cache.write("failures:#{url}", failures)
  end

  def error(message)
    @message = message
    @failures += 1
  end

  def pass
    @passes += 1
  end

  def free?
    tid.blank?
  end

  def free_and_viable?
    free? && viable?
  end

  def busy?
    !free?
  end

  def viable?
    return true if (passes + failures) < 32

    passes >= failures
  end

  def serialize
    {
      url: url,
      tid: tid,
      pass_rate: (passes.to_f / (passes + failures)).round(2),
      message: message,
    }
  end
end
