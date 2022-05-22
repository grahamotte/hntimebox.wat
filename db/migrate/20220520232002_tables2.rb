class Tables2 < ActiveRecord::Migration[7.0]
  def change
    create_table :proxies do |t|
      t.string :url
      t.timestamps
    end
    add_index :proxies, :url, unique: true

    create_table :proxy_timings do |t|
      t.references :proxy, null: false
      t.float :seconds, null: false
      t.boolean :failure, null: false, default: false
      t.timestamps
    end
  end
end
