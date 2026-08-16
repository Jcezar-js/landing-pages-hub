# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# --- início: lógica nossa (admin de desenvolvimento) ---
# Não existe tela pública de cadastro (decisão da Fase 4), então sem isso o painel
# fica inacessível depois de todo db:reset.
#
# Só roda em development/test de propósito: seeds é executado em qualquer ambiente
# (db:prepare roda em banco novo), e senha padrão em produção seria porta aberta.
# O admin de produção continua sendo criado à mão no console.
if Rails.env.local?
  admin = Admin.find_or_create_by!(email: ENV.fetch("ADMIN_EMAIL", "admin@example.com")) do |a|
    a.password = ENV.fetch("ADMIN_PASSWORD", "senha123456")
  end

  puts "Admin de desenvolvimento pronto: #{admin.email}"
end
# --- fim: lógica nossa ---
