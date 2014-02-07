class Sites::Admin::BackupsController < ApplicationController
  before_filter :require_user
  before_filter :check_authorization
  
  respond_to :html, :json

  def index
    respond_to do |format|
      format.html 
  end

  end

  def generate
    s = current_site    
    h = {include: {}}
    h[:include][:pages] = {include: :i18ns} if params[:pages]
    h[:include][:repositories] = {}  if params[:repositories]
    h[:include][:menus] = {include: :root_menu_items } if params[:menus]
    h[:include][:follow_styles] = {}  if params[:follow_styles]
    h[:include][:own_styles] = {}  if params[:own_styles]
    h[:include][:banners] = {}  if params[:banners]
    h[:include][:components] = {}  if params[:components]
    h[:include][:extensions] = {}  if params[:extensions]
    h[:include][:groupings] = {}  if params[:groupings]
    h[:include][:roles] = {include: :users}  if params[:roles]
    h[:include][:locales] = {}  if params[:locales]

    if params[:type] == "JSON"
    send_data(s.to_json(h) do |json|
        json.messages {Feedback::Message.where(site_id: s.id).each { |message| message.to_xml(skip_instruct: true, builder: json)  }} if params[:messages]
      end,
           :type => 'text/json; charset=UTF-8;',
           :disposition => "attachment; filename=#{s.name}.json") 
    elsif
      send_data(s.to_xml(h) do |xml|
        xml.messages {Feedback::Message.where(site_id: s.id).each { |message| message.to_xml(skip_instruct: true, builder: xml)  }} if params[:messages]
      end,
           :type => 'text/xml; charset=UTF-8;',
           :disposition => "attachment; filename=#{s.name}.xml")
    end
    
  end
  
  def import

    redirect_to :back
  end
  
end
