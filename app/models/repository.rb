class Repository < ActiveRecord::Base
  default_scope :order => 'updated_at DESC'

  def self.search(site_id, search, page, type)
    paginate :per_page => 4, :page => page, :conditions => ['site_id = ? AND archive_content_type LIKE ? AND description like ?', "#{site_id}","%#{type}%", "%#{search}%"], :order => 'id DESC'
  end
  belongs_to :site

	has_one :page
	has_one :banner
	
  has_many :pages_repositories
  has_many :pages, :through => :pages_repositories

  validates_presence_of :description
  has_attached_file :archive, :styles => { :medium => "300X300", :little =>"190X140"}, :url => "/uploads/:site_id/:style_:basename.:extension"
  validates_attachment_presence :archive, :message => I18n.t('activerecord.errors.messages.attachment_presence')
  #validates_attachment_content_type :mp3, :content_type => [ "image/bmp", "image/x-png", "image/pjpeg", "image/jpg", "image/jpeg", "image/png", "image/gif" ] 
end
