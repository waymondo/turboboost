#encoding: utf-8

class ItemsController < ApplicationController
  def show
    item = Item.find(params[:id])
    render json: item
  end

  def create
    @item = Item.create!(item_params)
    render :show, within: '#sidebar', flash: { notice: 'Item was successfully created.' }
  end

  def update
    item = Item.find(params[:id])
    item.update!(item_params)
    render nothing: true, notice: 'ééééé.'
  end

  private

  def item_params
    params.require(:item).permit(:name)
  end
end
