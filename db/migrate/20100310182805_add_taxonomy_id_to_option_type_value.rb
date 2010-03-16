class AddTaxonomyIdToOptionTypeValue < ActiveRecord::Migration
  def self.up
    add_column :option_values, :taxonomy_id, :integer
  end

  def self.down
    remove_column :option_values, :taxonomy_id
  end
end
