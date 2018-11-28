class Sites::Admin::SkinsController < ApplicationController
  before_action :require_user
  before_action :check_authorization
  before_action :load_skin, only: [:show, :destroy, :apply, :preview]

  def index
    skin = current_site.active_skin
    if skin
      redirect_to site_admin_skin_path(skin)
    else
      redirect_to new_site_admin_skin_path
    end
  end

  def show
    @active_skin = current_site.active_skin
    @skins = current_site.skins.order(:name).reject{|sk| sk.theme == @active_skin.theme }

    @components = @skin.components.includes(:skin).order(position: :asc)
    @placeholders = current_site.theme ? current_site.theme.layout['placeholders'] : []

    @styles = {}
    @styles[:others] = Style.not_followed_by(@skin).search(params[:search])
                            .order('sites.name, styles.name')
                            .page(params[:page]).per(params[:per_page])
    @styles[:styles] = @skin.styles.includes(:style, :followers, :site) if request.format.html?
  end

  def new
    installed_themes = current_site.skins.pluck(:theme)
    @themes = Weby::Themes.all.reject{|th| installed_themes.include?(th.name) }.sort_by(&:name)
    if !current_user.is_admin
      @themes.reject!{|th| th.is_private }
    end
  end

  def create
    theme = ::Weby::Themes.theme(params[:theme])
    skin = current_site.skins.find_by(theme: theme.name)
    if theme.is_private && !current_user.is_admin
      flash[:error] = t('only_admin')
      redirect_to site_admin_skins_path
      return
    end
    if skin.blank?
      skin = current_site.skins.create(name: theme.name.titleize, theme: theme.name)
      record_activity('theme_installed', skin)
    else
      # should NOT call this action for themes already installed
      flash[:error] = t('theme_already_installed')
      redirect_to site_admin_skin_path(skin)
      return
    end

    flash = t('successfully_installed_theme')
    if params[:apply].to_s == 'true'
      current_site.skins.update_all active: false
      skin.update active: true
      record_activity('theme_applied', skin)
      flash = t('successfully_applied_theme')
    end

    theme.populate skin, user: current_user
    flash[:success] = flash
    redirect_to site_admin_skin_path(skin)
  end

  def apply
    current_site.skins.update_all active: false
    @skin.update active: true
    record_activity('theme_applied', @skin)
    flash[:success] = t('successfully_applied_theme')
    redirect_to site_admin_skin_path(@skin)
  end

  def preview
    redirect_to site_path(preview_skin: @skin.id)
  end

  def destroy
    @skin.components.destroy_all
    @skin.styles.destroy_all

    @skin.base_theme.populate @skin, user: current_user
    flash[:success] = t('.successfully_reseted_theme')
    record_activity('theme_reseted', @skin)
    redirect_to site_admin_skin_path(@skin)
  end

  private

  def load_skin
    @skin = current_site.skins.find(params[:id])
  end
end
