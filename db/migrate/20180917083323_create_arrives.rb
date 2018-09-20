class CreateArrives < ActiveRecord::Migration
  def change
    create_table :arrives do |t|
      t.string :line_user_id
      t.boolean :arrive, default: false
      t.boolean :plan, default: false
      t.timestamps null: false
    end
  end
end
