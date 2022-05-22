require 'pry'

Thread.abort_on_exception = true
File.open('log/errors.txt', 'w') { |f| f << '' }
$things = []
$tps = []
$pp = ProxyPool.new
$all = (0..30_000_000).to_a
$done = Thing.all.pluck(&:id)

def fetch(id)
  X.try do
    $pp.req(url: "https://hacker-news.firebaseio.com/v0/item/#{id}.json")
  end
end

def collect(data = {}, id: nil)
  data[id] = nil if id.present?

  fetch_id = data.find { |_, v| v.nil? }&.first
  return data.values if fetch_id.blank?

  res = fetch(fetch_id)
  data[fetch_id] = res
  [res.dig(:parent), res.dig(:kids)].flatten.compact.each do |x|
    data[x] ||= nil
  end

  $things << res

  collect(data)
end

def unscanned_id
  id = nil
  loop do
    id = $all.sample
    break if $done.exclude?(id)
  end
  id
end

def call
  collect(id: unscanned_id)
rescue StandardError => e
  File.open('log/errors.txt', 'a') { |f| f << "#{e.message} #{e.backtrace.first}\n" }
end

creator = Thread.new do
  loop do
    $pp.recache
    $pp.unused_count.times do
      Thread.new { call }
    end
    sleep 5
  end
end

saver = Thread.new do
  loop do
    Thing.upsert_things($things.uniq { |x| x.dig(:id) })
      .to_a
      .map(&:values)
      .flatten
      .each { |x| $things.delete_if { |y| y.dig(:id) == x } }
      .then { |x| $done -= x; x }
      .then { |x| $tps << x.length.to_f / 5 }

    sleep 5
  end
end

Curses.init_screen
loop do
  Curses.clear
  Curses.addstr($pp.to_s)
  Curses.refresh
  sleep 0.1
end

trap("INT") do
  creator.kill
  saver.kill
end
