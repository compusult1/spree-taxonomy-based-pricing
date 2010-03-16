class CreateCatalogOptionType < ActiveRecord::Migration
  def self.up
    if OptionType.find(:all, :conditions => "name = 'catalog'").empty?
      OptionType.create :name => 'catalog', :presentation => 'Catalog'
    end
  end

  def self.down
  end
end
