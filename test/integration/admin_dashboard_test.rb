require "test_helper"

class AdminDashboardTest < ActionDispatch::IntegrationTest
  setup do
    sign_in admins(:one)
  end

  # --- início: lógica nossa (painel mostra o que falta fazer, não só totais) ---
  # "Quantos clientes ainda esperam landing page" é a pendência real do painel —
  # sai da mesma tabela que já é contada, sem schema novo.
  test "painel conta clientes sem landing page" do
    Client.destroy_all
    LandingPage.destroy_all
    com_lp = Client.create!(name: "Com LP")
    com_lp.create_landing_page!(slug: "com-lp")
    2.times { |i| Client.create!(name: "Sem LP #{i}") }

    get admin_root_path

    assert_response :success
    assert_select ".stat--pendencia", text: /2/
  end

  test "painel sem pendência não mostra o alerta" do
    Client.destroy_all
    LandingPage.destroy_all

    get admin_root_path

    assert_select ".stat--pendencia", count: 0
  end
  # --- fim: lógica nossa ---
end
