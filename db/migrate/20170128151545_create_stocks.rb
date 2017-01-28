class CreateStocks < ActiveRecord::Migration
  def change
    create_table :stocks do |t|
      t.string :ticker, unique: true

      t.timestamps null: false
    end
  end
end
