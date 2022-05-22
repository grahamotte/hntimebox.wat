class DropText < ActiveRecord::Migration[7.0]
  def change
    remove_column :items, :text, :string
  end
end
