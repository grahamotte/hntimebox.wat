class X
  def self.try(n: 20, s: 0, &block)
    block.call
  rescue StandardError => e
    raise e if n <= 0
    sleep(s) if s.positive?
    try(n: n - 1, s: s, &block)
  end
end
