class Tables < ActiveRecord::Migration[7.0]
  def change
    create_table :items do |t|
      t.bigint :parent
      t.string :title
      t.string :text
      t.string :url
      t.bigint :score
      t.bigint :descendants
      t.bigint :time
      t.string :by
      t.boolean :deleted
      t.boolean :dead
    end
  end
end
