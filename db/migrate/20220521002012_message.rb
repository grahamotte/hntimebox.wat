class Message < ActiveRecord::Migration[7.0]
  def change
    add_column :proxy_timings, :message, :string
  end
end
