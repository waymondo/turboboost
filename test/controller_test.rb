require 'test_helper'
Dir[File.dirname(__FILE__) + '/controllers/*.rb'].each { |file| require file }

class PostsControllerTest < ActionController::TestCase
  tests PostsController

  setup do
    @request.headers['X-Turboboost'] = '1'
  end

  test 'On a successful turboboost request, return an empty response with headers containing the redirect location and flash message' do
    xhr :post, :create, post: { title: 'Foobar', user_id: '1' }

    assert @response.body.strip.blank?
    assert_equal flash[:notice], 'Post was successfully created.'
    assert_equal @response.headers['Location'], posts_url
    assert_equal JSON.parse(@response.headers['X-Flash'])['notice'], 'Post was successfully created.'
  end

  test 'On an unsuccessful turboboost request, catch and return the error message(s) as an array' do
    xhr :post, :create, post: { title: 'Title', user_id: nil }

    assert_equal @response.status, 422
    assert_equal @response.body.strip, ['User can\'t be blank'].to_json

    xhr :post, :create, post: { title: 'Tit', user_id: nil }

    assert_equal @response.status, 422
    assert_equal @response.body.strip, ['Title is too short.', "User can't be blank"].to_json
  end
end

class UsersControllerTest < ActionController::TestCase
  tests UsersController

  setup do
    @request.headers['X-Turboboost'] = '1'
  end

  test 'On a successful turboboost request, return an empty response with headers containing the redirect location and flash message' do
    xhr :post, :create, user: { name: 'Mike', email: 'mike@mike.com' }

    assert @response.body.strip.blank?
    assert_equal flash[:notice], 'User was successfully created.'
    assert_equal @response.headers['Location'], user_url(1)
    assert_equal JSON.parse(@response.headers['X-Flash'])['notice'], 'User was successfully created.'
  end

  test 'On an unsuccessful turboboost request, explicitly render the error message(s)' do
    xhr :post, :create, user: { name: 'Mike', email: 'mike at mike.com' }

    assert_equal @response.status, 422
    assert_equal @response.body.strip, ['Email is invalid'].to_json
  end
end

class ItemsControllerTest < ActionController::TestCase
  tests ItemsController

  setup do
    @request.headers['X-Turboboost'] = '1'
  end

  test 'On a successful turboboost post request, return rendering options in the headers' do
    xhr :post, :create, item: { name: 'Bottle' }

    assert_equal @response.headers['Location'], nil
    assert_equal JSON.parse(@response.headers['X-Flash'])['notice'], 'Item was successfully created.'
    assert_equal @response.headers['X-Within'], '#sidebar'
    assert_equal @response.body.strip, "<div id=\"item\">Bottle</div>"
  end

  test 'On a successful turboboost update using render nothing: true, still return flash headers' do
    @item = Item.create(name: 'Opener')
    xhr :put, :update, id: @item.id, item: { name: 'Bottle Opener' }

    assert_equal @response.headers['Location'], nil
    assert_equal @response.body.strip, ''
    assert_equal JSON.parse(@response.headers['X-Flash'])['notice'], 'Item updated.'
  end
end
