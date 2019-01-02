class CreateUser2s < ActiveRecord::Migration
  def change
    create_table :user2s do |t|

      t.timestamps
    end
  end
end
