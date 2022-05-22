class Things < ActiveRecord::Migration[7.0]
  def change
    # id 	The item's unique id.
    # deleted 	true if the item is deleted.
    # type 	The type of item. One of "job", "story", "comment", "poll", or "pollopt".
    # by 	The username of the item's author.
    # time 	Creation date of the item, in Unix Time.
    # text 	The comment, story or poll text. HTML.
    # dead 	true if the item is dead.
    # parent 	The comment's parent: either another comment or the relevant story.
    # poll 	The pollopt's associated poll.
    # kids 	The ids of the item's comments, in ranked display order.
    # url 	The URL of the story.
    # score 	The story's score, or the votes for a pollopt.
    # title 	The title of the story, poll or job. HTML.
    # parts 	A list of related pollopts, in display order.
    # descendants 	In the case of stories or polls, the total comment count.

    create_table :things do |t|
      t.boolean :deleted
      t.string :type
      t.string :by
      t.bigint :time
      t.string :text
      t.boolean :dead
      t.bigint :parent
      t.bigint :poll
      t.string :kids
      t.string :url
      t.bigint :score
      t.string :title
      t.string :parts
      t.bigint :descendants
    end

    add_index :things, :time
    add_index :things, :type
    add_index :things, :title
    add_index :things, :by
  end
end
