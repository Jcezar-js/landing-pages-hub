# --- início: lógica nossa (CRUD de Section com formulário guiado pelo schema) ---
# Fluxo de dois passos, sem JavaScript: os campos dependem do component_type, e o
# servidor só sabe qual é depois que ele foi escolhido.
#
#   1. GET new                      → escolhe o tipo
#   2. GET new?component_type=hero  → campos daquele tipo (nada foi salvo ainda)
#   3. POST create                  → grava o bloco inteiro de uma vez
#
# O passo 1 não persiste de propósito: um bloco criado só com o tipo nasceria
# inválido (campo obrigatório vazio) e sujaria a LP se o admin desistisse no meio.
class Admin::SectionsController < ApplicationController
  layout "admin"

  before_action :set_landing_page
  before_action :set_section, only: %i[edit update destroy]

  def new
    @component_type = params[:component_type].presence_in(Section::COMPONENT_TYPES)
    @section = @landing_page.sections.build(component_type: @component_type)
  end

  def create
    @component_type = section_params[:component_type].presence_in(Section::COMPONENT_TYPES)
    @section = @landing_page.sections.build(
      component_type: @component_type,
      title: section_params[:title],
      position: section_params[:position].presence || next_position
    )
    @section.assign_data(data_params)

    if @component_type && @section.save
      redirect_to edit_admin_client_landing_page_path(@client), notice: "Bloco adicionado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @section.assign_attributes(updatable_attributes)
    @section.assign_data(data_params)

    if @section.save
      redirect_to edit_admin_client_landing_page_path(@client), notice: "Bloco atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @section.destroy
    redirect_to edit_admin_client_landing_page_path(@client), notice: "Bloco removido."
  end

  private

  def set_landing_page
    @client = Client.find(params[:client_id])
    @landing_page = @client.landing_page || raise(ActiveRecord::RecordNotFound)
  end

  # Busca pela associação, não por Section.find: garante que o bloco pertence à
  # LP daquele cliente, em vez de aceitar qualquer id da tabela.
  def set_section
    @section = @landing_page.sections.find(params[:id])
  end

  def next_position
    (@landing_page.sections.maximum(:position) || 0) + 1
  end

  # Só assinala o que veio no request. Assinalar direto do params gravaria nil
  # em cima do que já estava salvo quando a chave não vem — um PATCH que mexe só
  # em `data` apagaria o título e zeraria a posição, e um bloco sem posição vai
  # pro fim da LP e ainda faz o `next_position` repetir um número já usado.
  #
  # component_type fica de fora de propósito: trocar o tipo de um bloco existente
  # deixaria o `data` órfão (chaves do tipo antigo, campos do novo). Para mudar de
  # tipo, remover o bloco e criar outro.
  def updatable_attributes
    attributes = section_params.slice(:title, :position)
    attributes[:position] = @section.position if attributes[:position].blank?
    attributes
  end

  def section_params
    params.require(:section).permit(:component_type, :title, :position)
  end

  # `data` é permitido como hash aberto porque as chaves variam por tipo. A
  # whitelist de verdade é o Section#assign_data, que corta tudo que não estiver
  # no schema daquele component_type.
  #
  # O teste de tipo é o que impede um `section[data]` escalar ou array (request
  # forjado, campo renomeado no navegador) de estourar NoMethodError no permit!.
  def data_params
    raw = params.require(:section)[:data]
    raw.is_a?(ActionController::Parameters) ? raw.permit!.to_h : {}
  end
end
# --- fim: lógica nossa ---
