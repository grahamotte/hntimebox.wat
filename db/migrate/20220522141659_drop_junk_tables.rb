class DropJunkTables < ActiveRecord::Migration[7.0]
  def up
    drop_table :items
    drop_table :proxies
    drop_table :proxy_timings
  end

  def down
  end
end
