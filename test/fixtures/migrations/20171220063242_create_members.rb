class CreateMembers < ActiveRecord::Migration[5.1]
  def change
    create_table :members do |t|
      t.references :user, foreign_key: true
      t.references :group, type: :uuid, foreign_key: true

      t.timestamps
    end
  end
end
