class AssThread < ActiveRecord::Migration[7.0]
  def change
    add_column :proxies, :tid, :string
  end
end
