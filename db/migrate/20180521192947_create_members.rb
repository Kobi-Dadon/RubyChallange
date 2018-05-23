class CreateMembers < ActiveRecord::Migration[5.2]
  def change
    create_table :members do |t|
      t.string :name
      t.string :website
      t.string :short_web
      t.string :headers
      t.string :friends

      t.timestamps
    end
  end
end
