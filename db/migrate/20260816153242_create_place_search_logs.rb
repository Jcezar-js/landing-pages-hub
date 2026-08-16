class CreatePlaceSearchLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :place_search_logs do |t|
      t.string :query
      t.integer :results_count

      t.timestamps
    end

    # --- início: índice nosso ---
    # A contagem do mês corrente roda em toda visita à tela de prospecção.
    add_index :place_search_logs, :created_at
    # --- fim: índice nosso ---
  end
end
