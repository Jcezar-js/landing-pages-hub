class Section < ApplicationRecord
  # --- início: lógica nossa (campos de data governados pelo SectionSchema) ---
  # Deriva do schema em vez de repetir a lista: tipo declarado lá sem partial
  # correspondente (ou vice-versa) quebra teste, não a página do cliente.
  COMPONENT_TYPES = SectionSchema.component_types.freeze
  # --- fim: lógica nossa ---

  belongs_to :landing_page
  has_many :photos, -> { order(:position) }, dependent: :destroy

  validates :component_type, inclusion: { in: COMPONENT_TYPES }

  # --- início: lógica nossa (leitura e escrita de data pelo schema) ---
  validate :required_data_fields_present

  # Único jeito das partials lerem `data`. Acessar `data["titluo"]` direto
  # devolveria nil e renderizaria vazio sem avisar ninguém — aqui, chave que não
  # existe no schema do tipo estoura na hora, e o smoke test de renderização
  # (test/integration/landing_pages_test.rb) pega isso antes de virar produção.
  def value(key)
    unless SectionSchema.key?(component_type, key)
      raise ArgumentError,
            "#{key.inspect} não é um campo de #{component_type.inspect}. " \
            "Campos válidos: #{SectionSchema.keys_for(component_type).inspect}"
    end

    data[key.to_s]
  end

  # Escreve só o que o schema declara, e por cima do que já está salvo.
  #
  # O slice é a whitelist real (o `permit(data: {})` do controller deixa passar
  # hash arbitrário), e o merge é o que impede o formulário de apagar chave que
  # ele não conhece — dado de bloco antigo sobrevive a mudança de schema.
  def assign_data(attrs)
    fields = attrs.to_h.stringify_keys.slice(*SectionSchema.keys_for(component_type))
    self.data = data.merge(fields.to_h { |key, raw| [ key, coerce(key, raw) ] })
  end

  private

  # Campo de lista é editado como textarea, um item por linha — evita form
  # aninhado dinâmico só pra montar um array de strings.
  #
  # Só String e Array entram. Um request forjado (`section[data][titulo][x]=1`)
  # chegaria como Hash, que não é blank? e portanto passaria pela validação de
  # obrigatório — e a LP pública renderizaria o inspect do Hash. Virando nil, cai
  # na validação normal e o bloco não salva.
  def coerce(key, raw)
    if SectionSchema.field(component_type, key)&.type == :list
      items = case raw
      when Array  then raw
      when String then raw.split("\n")
      else []
      end

      items.filter_map { |item| item.strip.presence if item.is_a?(String) }
    else
      raw if raw.is_a?(String)
    end
  end

  def required_data_fields_present
    SectionSchema.fields_for(component_type).each do |field|
      errors.add(field.key.to_sym, "não pode ficar em branco") if field.required && data[field.key].blank?
    end
  end
  # --- fim: lógica nossa ---
end
