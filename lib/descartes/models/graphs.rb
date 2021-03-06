require 'cgi'
require 'uri'

class NilClass
  def method_missing(name, *args, &block)
  end
end

class Sequel::Model
  #def validates_url_format(input)
  #end
end

class Graph < Sequel::Model

  many_to_many :dashboards
  one_to_many :tags
  
  plugin :boolean_readers
  plugin :prepared_statements
  plugin :prepared_statements_safe
  plugin :validation_helpers
  plugin :association_dependencies, :tags => :destroy

  def before_validation
    super
    self.configuration = deconstruct(self.url)
    self.name ||= (JSON.parse(self.configuration)["name"].first || JSON.parse(self.configuration)["title"].first || "Please name me")
  end

  def validate
    super
    validates_presence :name
    validates_presence :url
    #validates_url_format self.url
  end

  def before_create
    super
    self.uuid = SecureRandom.hex(16)
    self.enabled = true
    self.created_at = Time.now
    self.updated_at = Time.now
    self.views = 0
  end

  def after_create
    super
    tags = []
    tags.each do |name|
      Tag.new(:name => name, :graph_id => self.id).save;
    end
  end

  def before_update
    super
    self.updated_at = Time.now
  end

  def before_destroy
    super
    Tag.filter(:graph_id => self.id).destroy
  end

  def deconstruct(url)
    CGI.parse(URI.parse(url).query).to_json
  end

  def restore
    self.enabled = true
    self.save
  end
end
