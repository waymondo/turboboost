class ItemsController < ApplicationController
  def create
    @item = Item.create!(item_params)
    flash[:notice] = 'Item was successfully created.'
    render :show, within: '#sidebar'
  end

  def update
    item = Item.find(params[:id])
    item.update_attributes!(item_params)
    flash[:notice] = 'Item updated.'
    render nothing: true
  end

  private

  def item_params
    params.require(:item).permit(:name)
  end
end
