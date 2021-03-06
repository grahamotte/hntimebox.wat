class ProxyPool
  attr_accessor :pool

  def initialize
    urls = begin
      if ENV['NOPROXY']
        ['localhost']
      elsif ENV['FINDPROXY']
        Rails.cache.clear

        `python proxy-scraper/proxyScraper.py -p http -o #{Rails.root.join('tmp/http.txt')}`
        `python proxy-scraper/proxyScraper.py -p https -o #{Rails.root.join('tmp/https.txt')}`

        [
          File.read(Rails.root.join('tmp/http.txt')).split(/[\r\n]+/).map(&:chomp).select(&:present?).map { |x| "http://#{x}" },
          File.read(Rails.root.join('tmp/https.txt')).split(/[\r\n]+/).map(&:chomp).select(&:present?).map { |x| "https://#{x}" },
        ].flatten.uniq { |x| x.split('//').last }.sample(265)
      else
        File.read(Rails.root.join('config/known_good_proxies.txt')).split(/[\r\n]+/).map(&:chomp).select(&:present?)
      end
    end

    @pool = urls
      .map { |x| [x, x, x] }
      .flatten
      .map { |x| Proxy.new(x) }
      .shuffle
  end

  def recache
    pool.each(&:cache_write)
  end

  def unused_count
    # always leave one proxy free for  buffer, but also don't enqueue too many threads at once
    [pool.count(&:viable?) - pool.count(&:busy?) - 1, 16].min
  end

  def reserve
    X.try(n: 30, s: 0.1) do
      pool.shuffle.find(&:free_and_viable?).tid = Thread.current.object_id
    end
  end

  def current
    pool.find { |x| x.tid == Thread.current.object_id }
  end

  def with_proxy
    reserve
    p = current
    res = yield
    p.pass
    res
  rescue StandardError => e
    p.error(e.message) if p.present?
    raise e
  ensure
    p.tid = nil if p.present?
  end

  def req(method: :get, url:, **params)
    with_proxy do
      Timeout::timeout(5) do
        RestClient::Request
          .execute(
            method: method,
            url: url,
            proxy: current.url == 'localhost' ? nil : current.url,
            **params
          )
          .then { |x| JSON.parse(x.body, symbolize_names: true) }
      end
    end
  end

  def to_s
    standard = ->(x, l) { x.to_s.ljust(l, ' ').first(l) }
    keys = pool.first.serialize.keys

    res = <<~TEXT
      proxies available: #{pool.count(&:viable?)} (#{pool.length} known)
      threads: #{pool.count(&:tid)}
      things: #{$things.length} (#{$tps.last(4).map { |x| x.round(2) }.join(', ')} tps)
    TEXT

    res << "\n"
    res << [
      standard.call('url', 32),
      standard.call('tid', 8),
      standard.call('pass%', 8),
      standard.call('passes', 8),
      standard.call('failures', 8),
      standard.call('message', 32),
    ].join(' ')

    res << "\n"

    pool.sort_by(&:pass_rate).reverse.first(32).map(&:serialize).each do |x|
      res << [
        standard.call(x[:url], 32),
        standard.call(x[:tid], 8),
        standard.call(x[:pass_rate], 8),
        standard.call(x[:passes], 8),
        standard.call(x[:failures], 8),
        standard.call(x[:message], 32),
      ].join(' ')
      res << "\n"
    end

    res
  end
end
