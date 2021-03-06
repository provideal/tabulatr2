require 'rails_helper'

describe Tabulatr::Data::Sorting do
  class DummySortingClass
    include Tabulatr::Data::Sorting
    def table_columns; end
  end

  before(:each) do
    @dummy = DummySortingClass.new
    @dummy.instance_variable_set('@relation', Product.all)
    @dummy.instance_variable_set('@table_name', 'products')
    @dummy.instance_variable_set('@base', Product)
    col_options = Tabulatr::ParamsBuilder.new(sort_sql: 'products.title', filter_sql: 'products.title')
    column = Tabulatr::Renderer::Column.from(
        name: :title,
        klass: Product,
        col_options: col_options,
        table_name: :products
    )
    allow(@dummy).to receive(:table_columns).and_return([column])
  end

  describe '.apply_sorting' do

    context 'no sortparam' do

      context 'with no default order given' do
        it 'sorts by primary_key descending' do
          @dummy.apply_sorting(nil)
          expect(@dummy.instance_variable_get('@relation').to_sql)
            .to match /ORDER BY products.id desc/
        end
      end
    end

    context 'sortparam given' do
      context 'sort by column of main table' do
        context 'sort by "title"' do
          it 'uses the given sortparam' do
            @dummy.apply_sorting('products.title desc')
            expect(@dummy.instance_variable_get('@relation').to_sql)
              .to match /ORDER BY products.title desc/
          end
        end
      end

      context 'sort by association column' do
        it 'sorts by vendor.name' do
          @dummy.instance_variable_set('@includes', [])
          col_options = Tabulatr::ParamsBuilder.new(sort_sql: 'vendors.name', filter_sql: 'vendors.name')
          assoc = Tabulatr::Renderer::Association.from(
              name: :name,
              table_name: :vendor,
              klass: Product,
              col_options: col_options
          )
          allow(@dummy).to receive(:table_columns).and_return([assoc])
          @dummy.apply_sorting('vendor:name desc')
          expect(@dummy.instance_variable_get('@relation').to_sql)
            .to match /ORDER BY vendors.name desc/
        end
      end

      context 'sort by custom sql' do
        it "sorts by products.title || '' || vendors.name" do
          @dummy.instance_variable_set('@includes', [])
          col_options = Tabulatr::ParamsBuilder.new(sort_sql: "products.title || '' || vendors.name", filter_sql: 'products.title')
          column = Tabulatr::Renderer::Column.from(
              name: :custom_column,
              klass: Product,
              col_options: col_options
          )
          allow(@dummy).to receive(:table_columns).and_return([column])
          @dummy.apply_sorting('custom_column asc')
          expect(@dummy.instance_variable_get('@relation').to_sql)
            .to match /ORDER BY products.title \|\| '' \|\| vendors.name asc/
        end
      end
    end
  end
end
