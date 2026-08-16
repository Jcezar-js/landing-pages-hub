# --- início: lógica nossa (schema de campos por component_type) ---
# Diz quais campos cada bloco tem. É o que permite o painel montar um formulário
# com campos nomeados ("Título", "Subtítulo") em vez de um textarea de JSON cru,
# onde errar uma chave salvava sem reclamar e a LP renderizava vazio.
#
# PORO, não ActiveRecord: schema é código, não dado editável em runtime. Uma
# tabela no banco não ajudaria — cada tipo novo exige a partial correspondente
# em app/views/sections/, escrita à mão de qualquer forma.
#
# Fonte de verdade única: Section::COMPONENT_TYPES deriva daqui, e as partials
# leem via Section#value, que estoura em chave fora do schema. Renomear uma
# chave sem atualizar os dois lados quebra teste em vez de quebrar em silêncio.
class SectionSchema
  # type: :string (uma linha), :text (parágrafo), :list (um item por linha).
  # A Fase 6 (Active Storage) deve entrar aqui como :image, sem mexer no resto.
  Field = Struct.new(:key, :label, :type, :required, keyword_init: true)

  def self.field_list(*specs)
    specs.map { |key, label, type, required| Field.new(key:, label:, type:, required:) }
  end
  private_class_method :field_list

  FIELDS = {
    "hero" => field_list(
      [ "titulo",    "Título",    :string, true ],
      [ "subtitulo", "Subtítulo", :string, false ]
    ),
    "servicos" => field_list(
      [ "itens", "Serviços (um por linha)", :list, true ]
    ),
    "depoimentos" => field_list(
      [ "itens", "Depoimentos (um por linha)", :list, true ]
    ),
    "contato_whatsapp" => field_list(
      [ "telefone", "WhatsApp com DDI e DDD, só dígitos (ex.: 5511999998888)", :string, true ]
    ),
    "mapa" => field_list(
      [ "endereco", "Endereço", :string, true ]
    ),
    "sobre_mim" => field_list(
      [ "bio", "Bio", :text, true ]
    ),
    "experiencia" => field_list(
      [ "itens", "Experiências (uma por linha)", :list, true ]
    )
  }.freeze

  def self.component_types
    FIELDS.keys
  end

  def self.fields_for(component_type)
    FIELDS.fetch(component_type, [])
  end

  def self.keys_for(component_type)
    fields_for(component_type).map(&:key)
  end

  # `key.to_s`: as chaves de jsonb vêm como String do banco e como Symbol quando
  # escritas em Ruby. Comparar sem normalizar rejeitaria :titulo dizendo que os
  # campos válidos são ["titulo"].
  def self.field(component_type, key)
    fields_for(component_type).find { |f| f.key == key.to_s }
  end

  def self.key?(component_type, key)
    field(component_type, key).present?
  end
end
# --- fim: lógica nossa ---
