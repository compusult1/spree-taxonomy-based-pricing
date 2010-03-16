# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class TaxonomyBasedPricingExtension < Spree::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/taxonomy_based_pricing"

  # Please use taxonomy_based_pricing/config/routes.rb instead for extension routes.

  # def self.require_gems(config)
  #   config.gem "gemname-goes-here", :version => '1.2.3'
  # end
  
  def activate

    # Add your extension tab to the admin.
    # Requires that you have defined an admin controller:
    # app/controllers/admin/yourextension_controller
    # and that you mapped your admin in config/routes

    #Admin::BaseController.class_eval do
    #  before_filter :add_yourextension_tab
    #
    #  def add_yourextension_tab
    #    # add_extension_admin_tab takes an array containing the same arguments expected
    #    # by the tab helper method:
    #    #   [ :extension_name, { :label => "Your Extension", :route => "/some/non/standard/route" } ]
    #    add_extension_admin_tab [ :yourextension ]
    #  end
    #end

    # make your helper avaliable in all views
    # Spree::BaseController.class_eval do
    #   helper YourHelper
    # end
    
    #  TO DO
    #  make certain option types non-editable
    #  display pricing based on taxonomy

    Spree::BaseController.class_eval do
     helper ProductsHelper
    end

    Taxonomy.class_eval do
      after_create :add_taxonomy_to_catalog_option_values
      after_update :update_associated_option_value_presentation_value
      #after_destroy :remove_taxonomy_from_catalog_option_type_values

      def add_taxonomy_to_catalog_option_values
        option_type = OptionType.find_by_name('catalog')
        option_type.option_values.create :name => self.name.gsub(/ /, '_').downcase, :presentation => self.name, :taxonomy_id => self.id
      end

      def update_associated_option_value_presentation_value
        option_value = OptionValue.find_by_taxonomy_id(self.id)
        option_value.presentation = self.name
        option_value.save
      end
      
      def self.associated_with_a_catalog
        OptionType.find_by_name('catalog').option_values.collect { |option_value| Taxonomy.find(option_value.taxonomy_id) }
      end
    end

    Variant.class_eval do
      after_create :add_product_to_catalog_taxonomy_unless_master_variant
      after_update :remove_product_from_catalog_taxonomy_if_deleted

      def catalog_option_value
        @catalog_option_value ||= option_values.collect{|ov| ov.taxonomy_id.nil? ? nil : ov }.compact.first
      end

      def add_product_to_catalog_taxonomy_unless_master_variant
        if not self.is_master? and not catalog_option_value.nil? 
          taxonomy = Taxonomy.find(catalog_option_value.taxonomy_id)
          self.product.taxons << taxonomy.root
        end
      end

      def remove_product_from_catalog_taxonomy_if_deleted
        unless deleted_at.nil?
          unless catalog_option_value.nil?
            taxonomy = Taxonomy.find(catalog_option_value.taxonomy_id)
            self.product.taxons.delete(taxonomy.root)
          end
        end
      end
    end

    Product.class_eval do
      after_create :add_catalog_option_type

      def add_catalog_option_type
        option_type = OptionType.find_by_name('catalog')
        self.option_types << option_type
      end

      def variant_for_taxon(taxon)
        Variant.find(:first, :include => :option_values, :conditions => { 'option_values.taxonomy_id' => taxon.taxonomy_id, 'variants.product_id' => self.id })
      end
    end

    ProductsHelper.class_eval do
      def catalog_price(product, taxon = nil)
        variant = taxon.nil? ? product : product.variant_for_taxon(taxon)
        object_to_price = variant.nil? ? product : variant
        product_price(object_to_price)
      end
    end

  end
end
